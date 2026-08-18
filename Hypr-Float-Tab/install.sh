#!/usr/bin/env bash
# ╭──────────────────────────────────────────────────────────────────────────╮
# │  install.sh — hypr-float-tab one-shot setup                              │
# │  Copies the script, wires the keybind, and patches your Hyprland config. │
# ╰──────────────────────────────────────────────────────────────────────────╯

set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────
GRN='\033[0;32m'; YLW='\033[0;33m'; RED='\033[0;31m'; DIM='\033[2m'; RST='\033[0m'
ok()   { echo -e "  ${GRN}✔${RST}  $*"; }
warn() { echo -e "  ${YLW}⚠${RST}  $*"; }
err()  { echo -e "  ${RED}✘${RST}  $*"; exit 1; }
step() { echo -e "\n${DIM}──────────────────────────────────────────────────${RST}\n  $*"; }

# ── Config ────────────────────────────────────────────────────────────────────
HYPR_DIR="${HOME}/.config/hypr"
SCRIPTS_DIR="${HYPR_DIR}/scripts"
HYPRLAND_DIR="${HYPR_DIR}/hyprland"
SCRIPT_SRC="$(cd "$(dirname "$0")" && pwd)/float-tab-toggle.sh"
SCRIPT_DEST="${SCRIPTS_DIR}/float-tab-toggle.sh"

# Keybind — change this to whatever you prefer
KEYBIND_MODS="Super+Shift"
KEYBIND_KEY="F"

# Size — percentage of monitor width × height
SIZE_W=50
SIZE_H=65

# ── Sanity checks ─────────────────────────────────────────────────────────────
step "Checking requirements"
command -v hyprctl &>/dev/null   || err "hyprctl not found — are you running Hyprland?"
command -v python3 &>/dev/null   || err "python3 not found — required for JSON parsing in the toggle script"
[[ -f "$SCRIPT_SRC" ]]           || err "float-tab-toggle.sh not found next to install.sh"
[[ -d "$HYPR_DIR" ]]             || err "~/.config/hypr not found — is Hyprland configured?"
ok "All requirements met"

# ── Detect config style (Lua vs legacy .conf) ─────────────────────────────────
step "Detecting Hyprland config style"
USE_LUA=false
[[ -f "${HYPRLAND_DIR}/keybinds.lua" ]] && USE_LUA=true

if $USE_LUA; then
    ok "Lua config detected (keybinds.lua / misc.lua / general.lua)"
else
    ok "Legacy .conf config detected"
fi

# ── Helper: idempotent file patch ─────────────────────────────────────────────
# patch_file <file> <guard_string> <line_to_append>
patch_file() {
    local file="$1" guard="$2" line="$3"
    if grep -qF "$guard" "$file" 2>/dev/null; then
        warn "Already present in $(basename "$file") — skipping"
    else
        echo "$line" >> "$file"
        ok "Patched $(basename "$file")"
    fi
}

# ── Step 1: Copy script ───────────────────────────────────────────────────────
step "Installing toggle script"
mkdir -p "$SCRIPTS_DIR"
if [[ -f "$SCRIPT_DEST" ]]; then
    cp "$SCRIPT_SRC" "$SCRIPT_DEST"
    ok "Updated ${SCRIPT_DEST}"
else
    cp "$SCRIPT_SRC" "$SCRIPT_DEST"
    ok "Installed ${SCRIPT_DEST}"
fi
chmod +x "$SCRIPT_DEST"

# Apply the custom size if different from defaults (50/65)
if [[ "$SIZE_W" != "50" || "$SIZE_H" != "65" ]]; then
    sed -i "s|WIN_W=\$(( MON_W \* 50 / 100 ))|WIN_W=\$(( MON_W * ${SIZE_W} / 100 ))|" "$SCRIPT_DEST"
    sed -i "s|WIN_H=\$(( MON_H \* 65 / 100 ))|WIN_H=\$(( MON_H * ${SIZE_H} / 100 ))|" "$SCRIPT_DEST"
    ok "Applied custom size: ${SIZE_W}% × ${SIZE_H}%"
fi

# ── Step 2: Wire the keybind ──────────────────────────────────────────────────
step "Wiring keybind (${KEYBIND_MODS} + ${KEYBIND_KEY})"

if $USE_LUA; then
    KB_FILE="${HYPRLAND_DIR}/keybinds.lua"
    KB_GUARD="float-tab-toggle.sh"
    # Convert "Super+Shift" to "SUPER + SHIFT" for Lua config
    LUA_MODS=$(echo "$KEYBIND_MODS" | tr '[:lower:]' '[:upper:]' | sed 's/+/ + /g')
    KB_LINE="hl.bind(\"${LUA_MODS} + ${KEYBIND_KEY}\", hl.dsp.exec_cmd(\"~/.config/hypr/scripts/float-tab-toggle.sh\"))  -- float-tab toggle"
    patch_file "$KB_FILE" "$KB_GUARD" "$KB_LINE"
else
    KB_FILE="${HYPRLAND_DIR}/keybinds.conf"
    KB_GUARD="float-tab-toggle.sh"
    KB_LINE="bind = ${KEYBIND_MODS}, ${KEYBIND_KEY}, exec, ~/.config/hypr/scripts/float-tab-toggle.sh  # float-tab toggle"
    patch_file "$KB_FILE" "$KB_GUARD" "$KB_LINE"
fi

# ── Step 3: Enable resize_on_border ──────────────────────────────────────────
step "Enabling border-drag resize (resize_on_border)"

if $USE_LUA; then
    GEN_FILE="${HYPRLAND_DIR}/general.lua"
    if grep -q "resize_on_border" "$GEN_FILE" 2>/dev/null; then
        # Flip false → true if needed
        sed -i 's/resize_on_border\s*=\s*false/resize_on_border        = true/' "$GEN_FILE"
        ok "resize_on_border already in general.lua (ensured true)"
    else
        # Append inside the general block — safest is to append before the closing })
        sed -i '/^}\s*$/{i\        resize_on_border        = true,   -- drag border to resize (no modifier)\n        extend_border_grab_area = 15,     -- wider invisible grab zone\n        hover_icon_on_border    = true,   -- show resize cursor on hover
        }' "$GEN_FILE" 2>/dev/null || {
            warn "Could not auto-patch general.lua — add manually:"
            warn "  resize_on_border        = true"
            warn "  extend_border_grab_area = 15"
            warn "  hover_icon_on_border    = true"
        }
    fi
else
    GEN_FILE="${HYPRLAND_DIR}/general.conf"
    if grep -q "resize_on_border" "$GEN_FILE" 2>/dev/null; then
        sed -i 's/resize_on_border\s*=\s*false/resize_on_border = true/' "$GEN_FILE"
        ok "resize_on_border already in general.conf (ensured true)"
    else
        patch_file "$GEN_FILE" "resize_on_border" "    resize_on_border = true"
        patch_file "$GEN_FILE" "extend_border_grab_area" "    extend_border_grab_area = 15"
        patch_file "$GEN_FILE" "hover_icon_on_border" "    hover_icon_on_border = true"
    fi
fi

# ── Step 4: Enable animate_manual_resizes ────────────────────────────────────
step "Enabling smooth resize animation (animate_manual_resizes)"

if $USE_LUA; then
    MISC_FILE="${HYPRLAND_DIR}/misc.lua"
    if grep -q "animate_manual_resizes" "$MISC_FILE" 2>/dev/null; then
        sed -i 's/animate_manual_resizes\s*=\s*false/animate_manual_resizes       = true /' "$MISC_FILE"
        ok "animate_manual_resizes set to true in misc.lua"
    else
        patch_file "$MISC_FILE" "animate_manual_resizes" "        animate_manual_resizes = true,  -- smooth border-drag resize"
    fi
else
    MISC_FILE="${HYPRLAND_DIR}/misc.conf"
    if grep -q "animate_manual_resizes" "$MISC_FILE" 2>/dev/null; then
        sed -i 's/animate_manual_resizes\s*=\s*false/animate_manual_resizes = true/' "$MISC_FILE"
        ok "animate_manual_resizes set to true in misc.conf"
    else
        patch_file "$MISC_FILE" "animate_manual_resizes" "    animate_manual_resizes = true"
    fi
fi

# ── Step 5: Verify Super+LMB move / Super+RMB resize binds exist ─────────────
step "Checking Super + Mouse binds (move & resize)"

MOVE_OK=false
RESIZE_OK=false
if $USE_LUA; then
    grep -q "mouse:272.*drag\|movewindow\|window.drag" "${HYPRLAND_DIR}/keybinds.lua" 2>/dev/null && MOVE_OK=true
    grep -q "mouse:273.*resize\|resizewindow\|window.resize" "${HYPRLAND_DIR}/keybinds.lua" 2>/dev/null && RESIZE_OK=true
else
    grep -q "mouse:272.*movewindow\|movewindow.*mouse:272" "${HYPRLAND_DIR}/keybinds.conf" 2>/dev/null && MOVE_OK=true
    grep -q "mouse:273.*resizewindow\|resizewindow.*mouse:273" "${HYPRLAND_DIR}/keybinds.conf" 2>/dev/null && RESIZE_OK=true
fi

if $MOVE_OK; then
    ok "Super + Left Click move bind already present"
else
    warn "Super + LMB move bind not found — adding it"
    if $USE_LUA; then
        echo 'hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })  -- move floating window' \
            >> "${HYPRLAND_DIR}/keybinds.lua"
    else
        echo 'bindm = Super, mouse:272, movewindow  # move floating window' \
            >> "${HYPRLAND_DIR}/keybinds.conf"
    fi
    ok "Added Super + Left Click move bind"
fi

if $RESIZE_OK; then
    ok "Super + Right Click resize bind already present"
else
    warn "Super + RMB resize bind not found — adding it"
    if $USE_LUA; then
        echo 'hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })  -- resize floating window (diagonal)' \
            >> "${HYPRLAND_DIR}/keybinds.lua"
    else
        echo 'bindm = Super, mouse:273, resizewindow  # resize floating window (diagonal)' \
            >> "${HYPRLAND_DIR}/keybinds.conf"
    fi
    ok "Added Super + Right Click resize bind"
fi

# ── Step 6: Reload Hyprland ───────────────────────────────────────────────────
step "Reloading Hyprland config"
if hyprctl reload -q 2>/dev/null; then
    ok "Hyprland reloaded successfully"
else
    warn "Could not reload Hyprland — run 'hyprctl reload' manually"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo -e "\n${GRN}┌─────────────────────────────────────────────────┐${RST}"
echo -e "${GRN}│  hypr-float-tab installed!                      │${RST}"
echo -e "${GRN}└─────────────────────────────────────────────────┘${RST}"
echo -e "\n  Keybind : ${YLW}${KEYBIND_MODS} + ${KEYBIND_KEY}${RST}"
echo -e "  Move    : ${YLW}Super + Left Click${RST} drag"
echo -e "  Resize  : ${YLW}Left Click & drag any border edge${RST}"
echo -e "\n  ${DIM}To change the keybind or size, edit the CONFIG section at the top of install.sh${RST}\n"
