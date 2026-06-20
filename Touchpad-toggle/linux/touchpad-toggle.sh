#!/usr/bin/env bash
# ============================================================================
# Touchpad Toggle Script for Linux
# ============================================================================
# Toggles the laptop touchpad ON/OFF.
# Auto-detects: X11 vs Wayland, GNOME vs KDE vs Sway vs generic.
#
# Usage:
#   ./touchpad-toggle.sh          # Toggle touchpad
#   ./touchpad-toggle.sh status   # Show current state
#   ./touchpad-toggle.sh on       # Force enable
#   ./touchpad-toggle.sh off      # Force disable
#
# Bind to Super+Ctrl+L using your DE's shortcut settings or see README.
# ============================================================================

set -euo pipefail

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/.touchpad-toggle-state"
NOTIFY_TIMEOUT=2000

# --- Notification helper ---
notify() {
    local title="$1"
    local body="$2"
    local icon="$3"
    if command -v notify-send &>/dev/null; then
        notify-send -t "$NOTIFY_TIMEOUT" -i "$icon" "$title" "$body" 2>/dev/null || true
    fi
}

# --- Detect display server ---
detect_display_server() {
    if [ "${XDG_SESSION_TYPE:-}" = "wayland" ]; then
        echo "wayland"
    elif [ "${XDG_SESSION_TYPE:-}" = "x11" ]; then
        echo "x11"
    elif [ -n "${WAYLAND_DISPLAY:-}" ]; then
        echo "wayland"
    elif [ -n "${DISPLAY:-}" ]; then
        echo "x11"
    else
        echo "unknown"
    fi
}

# --- Detect desktop environment ---
detect_de() {
    local de="${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-unknown}}"
    de=$(echo "$de" | tr '[:upper:]' '[:lower:]')

    case "$de" in
        *gnome*|*unity*|*budgie*|*cinnamon*|*pantheon*|*cosmic*)
            echo "gnome"
            ;;
        *kde*|*plasma*)
            echo "kde"
            ;;
        *sway*)
            echo "sway"
            ;;
        *hyprland*)
            echo "hyprland"
            ;;
        *xfce*)
            echo "xfce"
            ;;
        *mate*)
            echo "mate"
            ;;
        *)
            echo "generic"
            ;;
    esac
}

# ============================================================================
# GNOME (works on both X11 and Wayland)
# ============================================================================
gnome_get_state() {
    local val
    val=$(gsettings get org.gnome.desktop.peripherals.touchpad send-events 2>/dev/null)
    if [ "$val" = "'disabled'" ]; then
        echo "off"
    else
        echo "on"
    fi
}

gnome_set_state() {
    local target="$1"
    if [ "$target" = "off" ]; then
        gsettings set org.gnome.desktop.peripherals.touchpad send-events 'disabled'
    else
        gsettings set org.gnome.desktop.peripherals.touchpad send-events 'enabled'
    fi
}

# ============================================================================
# KDE Plasma (works on both X11 and Wayland via qdbus)
# ============================================================================
kde_get_state() {
    # Try qdbus6 first (Plasma 6), fallback to qdbus (Plasma 5)
    local qdbus_cmd=""
    if command -v qdbus6 &>/dev/null; then
        qdbus_cmd="qdbus6"
    elif command -v qdbus &>/dev/null; then
        qdbus_cmd="qdbus"
    else
        echo "unknown"
        return
    fi

    local enabled
    enabled=$($qdbus_cmd org.kde.KWin /org/kde/KWin/InputDevice/touchpad org.kde.KWin.InputDevice.enabled 2>/dev/null) || {
        # Try finding the touchpad device path dynamically
        local devpath
        devpath=$($qdbus_cmd org.kde.KWin /org/kde/KWin/InputDevice 2>/dev/null | grep -i touch | head -1) || true
        if [ -n "$devpath" ]; then
            enabled=$($qdbus_cmd org.kde.KWin "$devpath" org.kde.KWin.InputDevice.enabled 2>/dev/null) || true
        fi
    }

    if [ "$enabled" = "true" ]; then
        echo "on"
    elif [ "$enabled" = "false" ]; then
        echo "off"
    else
        echo "unknown"
    fi
}

kde_set_state() {
    local target="$1"
    local qdbus_cmd=""
    if command -v qdbus6 &>/dev/null; then
        qdbus_cmd="qdbus6"
    elif command -v qdbus &>/dev/null; then
        qdbus_cmd="qdbus"
    else
        return 1
    fi

    local val="true"
    [ "$target" = "off" ] && val="false"

    # Try the standard path first
    $qdbus_cmd org.kde.KWin /org/kde/KWin/InputDevice/touchpad org.kde.KWin.InputDevice.enabled "$val" 2>/dev/null && return 0

    # Try finding the touchpad device path dynamically
    local devpath
    devpath=$($qdbus_cmd org.kde.KWin /org/kde/KWin/InputDevice 2>/dev/null | grep -i touch | head -1) || true
    if [ -n "$devpath" ]; then
        $qdbus_cmd org.kde.KWin "$devpath" org.kde.KWin.InputDevice.enabled "$val" 2>/dev/null && return 0
    fi

    return 1
}

# ============================================================================
# Sway (Wayland compositor)
# ============================================================================
sway_get_state() {
    local status
    status=$(swaymsg -t get_inputs 2>/dev/null | \
        python3 -c "
import json, sys
inputs = json.load(sys.stdin)
for inp in inputs:
    if inp.get('type') == 'touchpad':
        events = inp.get('libinput', {}).get('send_events', 'enabled')
        print('off' if events == 'disabled' else 'on')
        sys.exit(0)
print('unknown')
" 2>/dev/null) || echo "unknown"
    echo "$status"
}

sway_set_state() {
    local target="$1"
    local touchpad_id
    touchpad_id=$(swaymsg -t get_inputs 2>/dev/null | \
        python3 -c "
import json, sys
inputs = json.load(sys.stdin)
for inp in inputs:
    if inp.get('type') == 'touchpad':
        print(inp['identifier'])
        sys.exit(0)
" 2>/dev/null) || true

    if [ -z "$touchpad_id" ]; then
        return 1
    fi

    if [ "$target" = "off" ]; then
        swaymsg "input '$touchpad_id' events disabled" &>/dev/null
    else
        swaymsg "input '$touchpad_id' events enabled" &>/dev/null
    fi
}

# ============================================================================
# Hyprland (Wayland compositor)
# ============================================================================
hyprland_get_state() {
    # Hyprland uses hyprctl and device keyword
    local state
    state=$(hyprctl getoption input:touchpad:disable_while_typing 2>/dev/null) || echo "unknown"
    # Hyprland doesn't have a direct toggle; use the keyword approach
    if [ -f "$STATE_FILE" ] && [ "$(cat "$STATE_FILE")" = "off" ]; then
        echo "off"
    else
        echo "on"
    fi
}

hyprland_set_state() {
    local target="$1"
    local touchpad_name
    touchpad_name=$(hyprctl devices -j 2>/dev/null | \
        python3 -c "
import json, sys
data = json.load(sys.stdin)
for dev in data.get('mice', []):
    name = dev.get('name', '').lower()
    if 'touchpad' in name or 'trackpad' in name:
        print(dev['name'])
        sys.exit(0)
" 2>/dev/null) || true

    if [ -z "$touchpad_name" ]; then
        return 1
    fi

    if [ "$target" = "off" ]; then
        hyprctl keyword "device[$touchpad_name]:enabled" false &>/dev/null
    else
        hyprctl keyword "device[$touchpad_name]:enabled" true &>/dev/null
    fi
}

# ============================================================================
# XFCE (X11, uses xinput under the hood)
# ============================================================================
# Falls through to xinput_* functions below

# ============================================================================
# Generic X11 (xinput) — fallback for any X11 session
# ============================================================================
xinput_find_touchpad() {
    # Search for touchpad device by common names
    local device
    device=$(xinput list --name-only 2>/dev/null | grep -iE 'touchpad|trackpad|glidepoint|synaptics|elan|alps' | head -1) || true
    if [ -z "$device" ]; then
        # Try by device property — look for devices with "libinput Tapping Enabled"
        local ids
        ids=$(xinput list --id-only 2>/dev/null) || true
        for id in $ids; do
            if xinput list-props "$id" 2>/dev/null | grep -qi "tapping enabled\|synaptics"; then
                device=$(xinput list --name-only 2>/dev/null | sed -n "${id}p" 2>/dev/null) || true
                [ -n "$device" ] && break
                # Alternative: use the id directly
                echo "$id"
                return
            fi
        done
    fi
    echo "$device"
}

xinput_get_state() {
    local device
    device=$(xinput_find_touchpad)
    if [ -z "$device" ]; then
        echo "unknown"
        return
    fi

    local enabled
    enabled=$(xinput list-props "$device" 2>/dev/null | grep -i "device enabled" | awk -F: '{print $2}' | tr -d '[:space:]') || true

    if [ "$enabled" = "1" ]; then
        echo "on"
    elif [ "$enabled" = "0" ]; then
        echo "off"
    else
        echo "unknown"
    fi
}

xinput_set_state() {
    local target="$1"
    local device
    device=$(xinput_find_touchpad)
    if [ -z "$device" ]; then
        return 1
    fi

    if [ "$target" = "off" ]; then
        xinput disable "$device" 2>/dev/null
    else
        xinput enable "$device" 2>/dev/null
    fi
}

# ============================================================================
# Main logic
# ============================================================================
main() {
    local action="${1:-toggle}"
    local display_server
    local de

    display_server=$(detect_display_server)
    de=$(detect_de)

    echo "Detected: display=$display_server, desktop=$de"

    # Determine which backend to use
    local backend=""
    case "$de" in
        gnome)
            if command -v gsettings &>/dev/null; then
                backend="gnome"
            fi
            ;;
        kde)
            if command -v qdbus6 &>/dev/null || command -v qdbus &>/dev/null; then
                backend="kde"
            fi
            ;;
        sway)
            if command -v swaymsg &>/dev/null; then
                backend="sway"
            fi
            ;;
        hyprland)
            if command -v hyprctl &>/dev/null; then
                backend="hyprland"
            fi
            ;;
    esac

    # Fallback: if no DE-specific backend, try xinput (X11) or gsettings (Wayland GNOME-based)
    if [ -z "$backend" ]; then
        if [ "$display_server" = "x11" ] && command -v xinput &>/dev/null; then
            backend="xinput"
        elif command -v gsettings &>/dev/null; then
            # Many Wayland compositors based on GNOME stack support gsettings
            backend="gnome"
        elif command -v xinput &>/dev/null; then
            backend="xinput"
        fi
    fi

    if [ -z "$backend" ]; then
        echo "ERROR: Could not find a supported method to toggle touchpad."
        echo "Please install one of: gsettings, xinput, swaymsg, qdbus"
        notify "Touchpad Toggle" "No supported backend found!" "dialog-error"
        exit 1
    fi

    echo "Using backend: $backend"

    # Get current state
    local current_state
    case "$backend" in
        gnome)    current_state=$(gnome_get_state)    ;;
        kde)      current_state=$(kde_get_state)      ;;
        sway)     current_state=$(sway_get_state)     ;;
        hyprland) current_state=$(hyprland_get_state)  ;;
        xinput)   current_state=$(xinput_get_state)    ;;
    esac

    # If we can't detect state, use state file
    if [ "$current_state" = "unknown" ]; then
        if [ -f "$STATE_FILE" ]; then
            current_state=$(cat "$STATE_FILE")
        else
            current_state="on"  # assume on by default
        fi
    fi

    # Determine target state
    local target_state
    case "$action" in
        on)     target_state="on"  ;;
        off)    target_state="off" ;;
        status)
            echo "Touchpad is currently: $current_state"
            exit 0
            ;;
        toggle|*)
            if [ "$current_state" = "on" ]; then
                target_state="off"
            else
                target_state="on"
            fi
            ;;
    esac

    # Apply the change
    local result=0
    case "$backend" in
        gnome)    gnome_set_state "$target_state"    || result=$? ;;
        kde)      kde_set_state "$target_state"      || result=$? ;;
        sway)     sway_set_state "$target_state"     || result=$? ;;
        hyprland) hyprland_set_state "$target_state"  || result=$? ;;
        xinput)   xinput_set_state "$target_state"    || result=$? ;;
    esac

    if [ $result -ne 0 ]; then
        echo "ERROR: Failed to toggle touchpad."
        notify "Touchpad Toggle" "Failed to toggle touchpad!" "dialog-error"
        exit 1
    fi

    # Save state
    echo "$target_state" > "$STATE_FILE"

    # Notify user
    if [ "$target_state" = "off" ]; then
        echo "✋ Touchpad DISABLED"
        notify "Touchpad Disabled" "Touchpad has been turned OFF" "input-touchpad-off"
    else
        echo "👆 Touchpad ENABLED"
        notify "Touchpad Enabled" "Touchpad has been turned ON" "input-touchpad-on"
    fi
}

main "$@"
