#!/usr/bin/env bash
# ============================================================================
# Touchpad Toggle — Linux Installer
# ============================================================================
# Installs the toggle script and sets up the keyboard shortcut (Super+Ctrl+L)
# for your desktop environment.
#
# Usage:
#   chmod +x install.sh
#   ./install.sh
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.local/bin"
SCRIPT_NAME="touchpad-toggle"
SOURCE_SCRIPT="$SCRIPT_DIR/touchpad-toggle.sh"

echo "╔══════════════════════════════════════════════╗"
echo "║     Touchpad Toggle — Linux Installer        ║"
echo "╚══════════════════════════════════════════════╝"
echo

# --- Install the script ---
mkdir -p "$INSTALL_DIR"
cp "$SOURCE_SCRIPT" "$INSTALL_DIR/$SCRIPT_NAME"
chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
echo "✅ Installed script to: $INSTALL_DIR/$SCRIPT_NAME"

# --- Ensure ~/.local/bin is in PATH ---
if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
    echo ""
    echo "⚠️  $INSTALL_DIR is not in your PATH."
    echo "   Add this to your ~/.bashrc or ~/.zshrc:"
    echo "   export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
fi

# --- Detect DE and set up shortcut ---
DE="${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-unknown}}"
DE_LOWER=$(echo "$DE" | tr '[:upper:]' '[:lower:]')

echo ""
echo "Detected desktop: $DE"
echo ""

setup_gnome_shortcut() {
    echo "Setting up GNOME custom shortcut..."

    # Find the next available custom keybinding slot
    local existing
    existing=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null) || existing="@as []"

    # Check if we already have a touchpad-toggle binding
    if echo "$existing" | grep -q "touchpad-toggle"; then
        echo "✅ Shortcut already exists in GNOME."
        return
    fi

    # Find the next available slot number
    local slot=0
    while echo "$existing" | grep -q "custom$slot"; do
        slot=$((slot + 1))
    done

    local path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${slot}/"

    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path name "Touchpad Toggle"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path command "$INSTALL_DIR/$SCRIPT_NAME"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path binding "<Super><Control>l"

    # Add the new path to the list
    if [ "$existing" = "@as []" ] || [ "$existing" = "[]" ]; then
        gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$path']"
    else
        # Remove trailing ] and add new entry
        local new_list
        new_list=$(echo "$existing" | sed "s|]$|, '$path']|")
        gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$new_list"
    fi

    echo "✅ GNOME shortcut configured: Super+Ctrl+L → Touchpad Toggle"
}

setup_kde_shortcut() {
    echo "Setting up KDE Plasma shortcut..."

    local khotkeys_dir="$HOME/.config"
    local shortcuts_file="$khotkeys_dir/kglobalshortcutsrc"

    # For KDE Plasma, we can use kwriteconfig5/6
    local kwrite_cmd=""
    if command -v kwriteconfig6 &>/dev/null; then
        kwrite_cmd="kwriteconfig6"
    elif command -v kwriteconfig5 &>/dev/null; then
        kwrite_cmd="kwriteconfig5"
    fi

    if [ -n "$kwrite_cmd" ]; then
        # Create a custom shortcut via .desktop file
        local desktop_dir="$HOME/.local/share/applications"
        mkdir -p "$desktop_dir"

        cat > "$desktop_dir/touchpad-toggle.desktop" << EOF
[Desktop Entry]
Name=Touchpad Toggle
Comment=Toggle laptop touchpad on/off
Exec=$INSTALL_DIR/$SCRIPT_NAME
Icon=input-touchpad
Terminal=false
Type=Application
Categories=Utility;
EOF
        echo "✅ Created .desktop entry for KDE."
        echo ""
        echo "📋 To set the shortcut in KDE Plasma:"
        echo "   1. Open System Settings → Shortcuts → Custom Shortcuts"
        echo "   2. Click 'Add New' → 'Global Shortcut' → 'Command/URL'"
        echo "   3. Set the trigger to: Super+Ctrl+L"
        echo "   4. Set the action to: $INSTALL_DIR/$SCRIPT_NAME"
    else
        echo "⚠️  Could not auto-configure KDE shortcut."
        echo "   Manually add the shortcut in System Settings → Shortcuts."
    fi
}

setup_xfce_shortcut() {
    echo "Setting up XFCE shortcut..."

    if command -v xfconf-query &>/dev/null; then
        xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Super><Control>l" \
            -n -t string -s "$INSTALL_DIR/$SCRIPT_NAME" 2>/dev/null && \
            echo "✅ XFCE shortcut configured: Super+Ctrl+L → Touchpad Toggle" || \
            echo "⚠️  Failed to set XFCE shortcut. Set it manually in Settings → Keyboard → Application Shortcuts."
    else
        echo "⚠️  xfconf-query not found. Set the shortcut manually in XFCE settings."
    fi
}

setup_sway_shortcut() {
    echo "Setting up Sway shortcut..."

    local sway_config="$HOME/.config/sway/config"
    if [ -f "$sway_config" ]; then
        if grep -q "touchpad-toggle" "$sway_config"; then
            echo "✅ Sway shortcut already exists."
        else
            echo "" >> "$sway_config"
            echo "# Touchpad Toggle" >> "$sway_config"
            echo "bindsym Mod4+Control+l exec $INSTALL_DIR/$SCRIPT_NAME" >> "$sway_config"
            echo "✅ Added to Sway config: Mod4+Control+l → Touchpad Toggle"
            echo "   Reload Sway with: swaymsg reload"
        fi
    else
        echo "⚠️  Sway config not found at: $sway_config"
        echo "   Add this line to your Sway config:"
        echo "   bindsym Mod4+Control+l exec $INSTALL_DIR/$SCRIPT_NAME"
    fi
}

setup_hyprland_shortcut() {
    echo "Setting up Hyprland shortcut..."

    local hypr_config="$HOME/.config/hypr/hyprland.conf"
    if [ -f "$hypr_config" ]; then
        if grep -q "touchpad-toggle" "$hypr_config"; then
            echo "✅ Hyprland shortcut already exists."
        else
            echo "" >> "$hypr_config"
            echo "# Touchpad Toggle" >> "$hypr_config"
            echo "bind = SUPER CTRL, L, exec, $INSTALL_DIR/$SCRIPT_NAME" >> "$hypr_config"
            echo "✅ Added to Hyprland config: Super+Ctrl+L → Touchpad Toggle"
        fi
    else
        echo "⚠️  Hyprland config not found at: $hypr_config"
        echo "   Add this line to your Hyprland config:"
        echo "   bind = SUPER CTRL, L, exec, $INSTALL_DIR/$SCRIPT_NAME"
    fi
}

setup_generic_shortcut() {
    echo "📋 Your desktop environment ($DE) doesn't have automatic shortcut setup."
    echo ""
    echo "Manual setup options:"
    echo ""
    echo "  Option 1: Use xbindkeys (X11)"
    echo "    Install xbindkeys, then add to ~/.xbindkeysrc:"
    echo "    \"$INSTALL_DIR/$SCRIPT_NAME\""
    echo "      Mod4+Control+l"
    echo ""
    echo "  Option 2: Use swhkd (Wayland)"
    echo "    Install swhkd, then add to ~/.config/swhkd/swhkdrc:"
    echo "    super + ctrl + l"
    echo "      $INSTALL_DIR/$SCRIPT_NAME"
    echo ""
    echo "  Option 3: Use your DE's keyboard shortcut settings"
    echo "    Command: $INSTALL_DIR/$SCRIPT_NAME"
    echo "    Shortcut: Super+Ctrl+L"
}

# Set up the shortcut based on DE
case "$DE_LOWER" in
    *gnome*|*unity*|*budgie*|*cinnamon*|*pantheon*|*cosmic*)
        setup_gnome_shortcut
        ;;
    *kde*|*plasma*)
        setup_kde_shortcut
        ;;
    *xfce*)
        setup_xfce_shortcut
        ;;
    *sway*)
        setup_sway_shortcut
        ;;
    *hyprland*)
        setup_hyprland_shortcut
        ;;
    *)
        setup_generic_shortcut
        ;;
esac

echo ""
echo "════════════════════════════════════════════════"
echo "✅ Installation complete!"
echo ""
echo "   Toggle touchpad:  $SCRIPT_NAME"
echo "   Check status:     $SCRIPT_NAME status"
echo "   Force on:         $SCRIPT_NAME on"
echo "   Force off:        $SCRIPT_NAME off"
echo "   Keyboard shortcut: Super + Ctrl + L"
echo "════════════════════════════════════════════════"
