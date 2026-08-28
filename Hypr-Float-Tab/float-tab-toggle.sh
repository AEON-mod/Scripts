#!/usr/bin/env bash
# ╭──────────────────────────────────────────────────────────────╮
# │  float-tab-toggle.sh                                         │
# │  Toggles the focused window into/out of "float-tab" mode:   │
# │    ON  → float · resize to 50%×65% · center · pin           │
# │    OFF → unpin · un-float (return to tiling)                 │
# │                                                              │
# │  Move   : Super + Left Click  (bindm, set globally)          │
# │  Resize : drag any border     (resize_on_border = true)      │
# ╰──────────────────────────────────────────────────────────────╯

# ── Fetch active window state in one call ────────────────────────
WIN=$(hyprctl activewindow -j 2>/dev/null)
[[ -z "$WIN" || "$WIN" == "null" ]] && exit 0

IS_FLOATING=$(echo "$WIN" | python3 -c "import sys,json;w=json.load(sys.stdin);print(str(w.get('floating',False)).lower())")
IS_PINNED=$(echo   "$WIN" | python3 -c "import sys,json;w=json.load(sys.stdin);print(str(w.get('pinned',False)).lower())")
ADDRESS=$(echo     "$WIN" | python3 -c "import sys,json;w=json.load(sys.stdin);print(w.get('address',''))")
WORKSPACE=$(echo   "$WIN" | python3 -c "import sys,json;w=json.load(sys.stdin);print(w.get('workspace',{}).get('name',''))")

STATE_FILE="/tmp/hypr-float-tab-${ADDRESS}.ws"

# ── Toggle OFF: already floating + pinned → restore to tiled ─────
if [[ "$IS_FLOATING" == "true" && "$IS_PINNED" == "true" ]]; then
    hyprctl eval "hl.dispatch(hl.dsp.window.pin({   action = \"off\", window = \"address:${ADDRESS}\" }))" -q
    hyprctl eval "hl.dispatch(hl.dsp.window.float({ action = \"off\", window = \"address:${ADDRESS}\" }))" -q
    
    if [[ -f "$STATE_FILE" ]]; then
        ORIG_WS=$(cat "$STATE_FILE")
        if [[ -n "$ORIG_WS" ]]; then
            hyprctl eval "hl.dispatch(hl.dsp.window.move({ workspace = \"${ORIG_WS}\", silent = true, window = \"address:${ADDRESS}\" }))" -q
            
            # If returning to a special workspace, auto-open it so the window doesn't vanish
            if [[ "$ORIG_WS" == special:* ]]; then
                CURRENT_SPECIAL=$(hyprctl monitors -j | python3 -c "import sys,json; print(next((m.get('specialWorkspace', {}).get('name') for m in json.load(sys.stdin) if m.get('focused')), ''))")
                if [[ "$CURRENT_SPECIAL" != "$ORIG_WS" ]]; then
                    hyprctl eval "hl.dispatch(hl.dsp.workspace.toggle_special(\"${ORIG_WS#special:}\"))" -q
                fi
            fi
        fi
        rm -f "$STATE_FILE"
    fi
    exit 0
fi

# ── Toggle ON: enter float-tab mode ──────────────────────────────
# Save the current workspace to return to it later
echo "$WORKSPACE" > "$STATE_FILE"

# Get monitor logical size (respects HiDPI scale)
read -r MON_W MON_H < <(hyprctl monitors -j | python3 -c "
import sys, json
m = json.load(sys.stdin)[0]
scale = m.get('scale', 1.0)
print(int(m['width'] / scale), int(m['height'] / scale))
")

WIN_W=$(( MON_W * 50 / 100 ))
WIN_H=$(( MON_H * 65 / 100 ))

# Float (if not already)
[[ "$IS_FLOATING" != "true" ]] && {
    hyprctl eval "hl.dispatch(hl.dsp.window.float({ action = \"on\", window = \"address:${ADDRESS}\" }))" -q
    sleep 0.04   # wait for compositor to register the float state
}

# Resize → center → pin  (batched in one eval call)
hyprctl eval "
    hl.dispatch(hl.dsp.window.resize({ x = ${WIN_W}, y = ${WIN_H}, exact = true, window = \"address:${ADDRESS}\" }))
    hl.dispatch(hl.dsp.window.center({ window = \"address:${ADDRESS}\" }))
    hl.dispatch(hl.dsp.window.pin({   action = \"on\",  window = \"address:${ADDRESS}\" }))
" -q

# Auto-close special workspace if it is now empty (has no unpinned windows)
if [[ "$WORKSPACE" == special:* ]]; then
    # Wait briefly for Hyprland to process the pin
    sleep 0.1
    WS_WINDOWS=$(hyprctl clients -j | python3 -c "import sys,json; print(sum(1 for c in json.load(sys.stdin) if c.get('workspace',{}).get('name') == '$WORKSPACE' and not c.get('pinned', False)))")
    if [[ "$WS_WINDOWS" -eq 0 ]]; then
        hyprctl eval "hl.dispatch(hl.dsp.workspace.toggle_special(\"${WORKSPACE#special:}\"))" -q
    fi
fi
