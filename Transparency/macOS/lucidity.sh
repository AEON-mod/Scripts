#!/usr/bin/env bash
# ============================================================
#  Lucidity — AEON Transparency Manager for macOS
#  Per-app window opacity via yabai + skhd
# ============================================================
#
#  DEPENDENCIES:
#    brew install koekeishiya/formulae/yabai
#    brew install koekeishiya/formulae/skhd
#
#  This script is the backend. Hotkeys are defined in .skhdrc.
#  Run:  chmod +x lucidity.sh
# ============================================================

set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/lucidity"
CONFIG_FILE="$CONFIG_DIR/opacity.conf"
STATE_FILE="$CONFIG_DIR/.state"
STEP=0.05          # 5% per step
MIN_OPACITY=0.15
MAX_OPACITY=1.0
DEFAULT_OPACITY=0.85

# ─── Helpers ────────────────────────────────────────────────

ensure_config() {
    mkdir -p "$CONFIG_DIR"
    touch "$CONFIG_FILE"
    touch "$STATE_FILE"
}

# Get the bundle-id or process name of the focused window
get_focused_app() {
    yabai -m query --windows --window 2>/dev/null \
        | python3 -c "import sys,json; w=json.load(sys.stdin); print(w.get('app',''))" 2>/dev/null
}

get_focused_window_id() {
    yabai -m query --windows --window 2>/dev/null \
        | python3 -c "import sys,json; w=json.load(sys.stdin); print(w.get('id',''))" 2>/dev/null
}

# Read saved opacity for an app (returns empty string if not set)
get_saved_opacity() {
    local app="$1"
    grep -i "^${app}=" "$CONFIG_FILE" 2>/dev/null | head -1 | cut -d'=' -f2
}

# Write opacity for an app to config
save_opacity() {
    local app="$1"
    local val="$2"
    # Remove old entry (case-insensitive), then append
    grep -iv "^${app}=" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" 2>/dev/null || true
    echo "${app}=${val}" >> "${CONFIG_FILE}.tmp"
    mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
}

# Remove app from config
remove_opacity() {
    local app="$1"
    grep -iv "^${app}=" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" 2>/dev/null || true
    mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
}

# Check if transparency is paused for an app
is_paused() {
    local app="$1"
    grep -qi "^paused:${app}$" "$STATE_FILE" 2>/dev/null
}

set_paused() {
    local app="$1"
    if ! is_paused "$app"; then
        echo "paused:${app}" >> "$STATE_FILE"
    fi
}

unset_paused() {
    local app="$1"
    grep -iv "^paused:${app}$" "$STATE_FILE" > "${STATE_FILE}.tmp" 2>/dev/null || true
    mv "${STATE_FILE}.tmp" "$STATE_FILE"
}

# Clamp a float between min and max
clamp() {
    python3 -c "print(max($2, min($3, $1)))"
}

# Send macOS notification
notify() {
    osascript -e "display notification \"$1\" with title \"Lucidity\""
}

# Apply opacity to all windows of an app
apply_to_all_windows() {
    local app="$1"
    local opacity="$2"
    yabai -m query --windows 2>/dev/null \
        | python3 -c "
import sys, json
windows = json.load(sys.stdin)
for w in windows:
    if w.get('app','').lower() == '${app}'.lower():
        print(w['id'])
" 2>/dev/null | while read -r wid; do
        yabai -m window "$wid" --opacity "$opacity" 2>/dev/null || true
    done
}

# ─── Commands ───────────────────────────────────────────────

cmd_adjust() {
    local direction="$1"   # "up" or "down"
    ensure_config

    local app
    app=$(get_focused_app)
    [[ -z "$app" ]] && exit 0

    local current
    current=$(get_saved_opacity "$app")
    [[ -z "$current" ]] && current="$MAX_OPACITY"

    local new_val
    if [[ "$direction" == "up" ]]; then
        new_val=$(python3 -c "print(round($current + $STEP, 2))")
    else
        new_val=$(python3 -c "print(round($current - $STEP, 2))")
    fi
    new_val=$(clamp "$new_val" "$MIN_OPACITY" "$MAX_OPACITY")

    save_opacity "$app" "$new_val"
    apply_to_all_windows "$app" "$new_val"

    local pct
    pct=$(python3 -c "print(int($new_val * 100))")
    notify "${app}: ${pct}% opacity"
}

cmd_reset() {
    ensure_config
    local app
    app=$(get_focused_app)
    [[ -z "$app" ]] && exit 0

    remove_opacity "$app"
    unset_paused "$app"
    apply_to_all_windows "$app" "1.0"
    notify "${app}: Reset to 100%"
}

cmd_toggle() {
    ensure_config
    local app
    app=$(get_focused_app)
    [[ -z "$app" ]] && exit 0

    local saved
    saved=$(get_saved_opacity "$app")
    if [[ -z "$saved" ]]; then
        notify "${app}: No opacity configured"
        exit 0
    fi

    if is_paused "$app"; then
        unset_paused "$app"
        apply_to_all_windows "$app" "$saved"
        notify "${app}: Transparency ON"
    else
        set_paused "$app"
        apply_to_all_windows "$app" "1.0"
        notify "${app}: Transparency OFF"
    fi
}

cmd_pin() {
    ensure_config
    local wid
    wid=$(get_focused_window_id)
    local app
    app=$(get_focused_app)
    [[ -z "$wid" ]] && exit 0

    # yabai's "sticky" is the equivalent of Always-On-Top
    local is_sticky
    is_sticky=$(yabai -m query --windows --window "$wid" 2>/dev/null \
        | python3 -c "import sys,json; print(json.load(sys.stdin).get('is-sticky', False))" 2>/dev/null)

    if [[ "$is_sticky" == "True" ]]; then
        yabai -m window "$wid" --toggle sticky 2>/dev/null || true
        yabai -m window "$wid" --toggle topmost 2>/dev/null || true
        notify "${app}: Unpinned"
    else
        yabai -m window "$wid" --toggle sticky 2>/dev/null || true
        yabai -m window "$wid" --toggle topmost 2>/dev/null || true
        notify "${app}: Pinned (Always-On-Top)"
    fi
}

cmd_set() {
    # Interactive set:  lucidity.sh set <opacity>
    # e.g. lucidity.sh set 0.75
    ensure_config
    local opacity="${1:-$DEFAULT_OPACITY}"
    local app
    app=$(get_focused_app)
    [[ -z "$app" ]] && exit 0

    opacity=$(clamp "$opacity" "$MIN_OPACITY" "$MAX_OPACITY")
    save_opacity "$app" "$opacity"
    apply_to_all_windows "$app" "$opacity"

    local pct
    pct=$(python3 -c "print(int($opacity * 100))")
    notify "${app}: Set to ${pct}%"
}

cmd_sync() {
    # Daemon mode: continuously re-applies saved opacities.
    # Run in background:  lucidity.sh sync &
    ensure_config
    echo "Lucidity sync daemon started (PID $$)"

    while true; do
        while IFS='=' read -r app opacity; do
            [[ -z "$app" || -z "$opacity" ]] && continue
            is_paused "$app" && continue
            apply_to_all_windows "$app" "$opacity"
        done < "$CONFIG_FILE"
        sleep 2
    done
}

cmd_list() {
    ensure_config
    if [[ ! -s "$CONFIG_FILE" ]]; then
        echo "No apps configured."
        exit 0
    fi
    echo "─── Lucidity Opacity Config ───"
    while IFS='=' read -r app opacity; do
        [[ -z "$app" ]] && continue
        local pct
        pct=$(python3 -c "print(int($opacity * 100))")
        local status=""
        is_paused "$app" && status=" (paused)"
        printf "  %-30s %3s%%%s\n" "$app" "$pct" "$status"
    done < "$CONFIG_FILE"
}

cmd_help() {
    cat <<'EOF'
Lucidity — AEON Transparency Manager for macOS

Usage:  lucidity.sh <command> [args]

Commands:
  up          Increase opacity of focused app (+5%)
  down        Decrease opacity of focused app (-5%)
  set <val>   Set opacity directly (0.15–1.0)
  reset       Reset focused app to 100%
  toggle      Toggle transparency ON/OFF for focused app
  pin         Toggle Always-On-Top for focused window
  sync        Start background sync daemon
  list        Show all configured apps
  help        Show this message

Hotkeys are configured via skhd. See .skhdrc for bindings.
EOF
}

# ─── Dispatch ───────────────────────────────────────────────

ensure_config

case "${1:-help}" in
    up)      cmd_adjust "up"   ;;
    down)    cmd_adjust "down" ;;
    set)     cmd_set "${2:-}"  ;;
    reset)   cmd_reset         ;;
    toggle)  cmd_toggle        ;;
    pin)     cmd_pin           ;;
    sync)    cmd_sync          ;;
    list)    cmd_list          ;;
    help|*)  cmd_help          ;;
esac
