#!/usr/bin/env bash
# ============================================================================
# Touchpad Toggle — macOS
# ============================================================================
# Toggles the "Ignore built-in trackpad when mouse is present" setting.
#
# ⚠️  IMPORTANT LIMITATIONS:
#   - An external mouse or trackpad MUST be connected for this to work.
#   - Apple does not provide a public API to fully disable the internal
#     trackpad without an external pointing device.
#   - On macOS Ventura (13)+ the defaults method may not take effect
#     immediately; a logout/login may be required.
#
# Usage:
#   ./touchpad-toggle.sh          # Toggle
#   ./touchpad-toggle.sh status   # Show current state
#   ./touchpad-toggle.sh on       # Force enable trackpad
#   ./touchpad-toggle.sh off      # Force disable trackpad
#
# For the keyboard shortcut, see README for Karabiner-Elements setup.
# ============================================================================

set -euo pipefail

STATE_FILE="$HOME/.touchpad-toggle-state"

# --- Notification helper ---
notify() {
    local title="$1"
    local body="$2"
    osascript -e "display notification \"$body\" with title \"$title\"" 2>/dev/null || true
}

# --- Check if external mouse is connected ---
check_external_mouse() {
    # Check for USB or Bluetooth mice
    local mouse_count
    mouse_count=$(system_profiler SPUSBDataType SPBluetoothDataType 2>/dev/null | grep -ci "mouse\|trackball" || echo "0")
    if [ "$mouse_count" -eq 0 ]; then
        echo ""
        echo "⚠️  WARNING: No external mouse detected."
        echo "   macOS requires an external mouse/trackpad to be connected"
        echo "   before the internal trackpad can be disabled."
        echo "   Connect an external mouse and try again."
        echo ""
    fi
}

# --- Get current state ---
get_state() {
    # Check the "ignore trackpad" accessibility setting
    local ignore_trackpad
    ignore_trackpad=$(defaults read com.apple.AppleMultitouchTrackpad USBMouseStopsTrackpad 2>/dev/null || echo "0")

    if [ "$ignore_trackpad" = "1" ]; then
        echo "off"  # trackpad is being ignored
    else
        echo "on"   # trackpad is active
    fi
}

# --- Set state ---
set_state() {
    local target="$1"

    if [ "$target" = "off" ]; then
        # Disable trackpad (ignore it when external mouse present)
        defaults write com.apple.AppleMultitouchTrackpad USBMouseStopsTrackpad -int 1
        defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad USBMouseStopsTrackpad -int 1

        # Also try the Accessibility preference (more reliable on newer macOS)
        defaults write com.apple.Accessibility MouseIgnoresInternalTrackpad -int 1 2>/dev/null || true

        echo "$target" > "$STATE_FILE"
        echo "✋ Trackpad DISABLED (ignored when external mouse present)"
        notify "Trackpad Disabled" "Internal trackpad has been turned OFF"
    else
        # Enable trackpad
        defaults write com.apple.AppleMultitouchTrackpad USBMouseStopsTrackpad -int 0
        defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad USBMouseStopsTrackpad -int 0
        defaults write com.apple.Accessibility MouseIgnoresInternalTrackpad -int 0 2>/dev/null || true

        echo "$target" > "$STATE_FILE"
        echo "👆 Trackpad ENABLED"
        notify "Trackpad Enabled" "Internal trackpad has been turned ON"
    fi

    echo ""
    echo "ℹ️  Note: You may need to log out and back in for changes to take effect"
    echo "   on macOS Ventura (13) and later."
}

# --- Main ---
main() {
    local action="${1:-toggle}"

    local current_state
    current_state=$(get_state)

    case "$action" in
        status)
            echo "Trackpad is currently: $current_state"
            exit 0
            ;;
        on)
            set_state "on"
            ;;
        off)
            check_external_mouse
            set_state "off"
            ;;
        toggle|*)
            if [ "$current_state" = "on" ]; then
                check_external_mouse
                set_state "off"
            else
                set_state "on"
            fi
            ;;
    esac
}

main "$@"
