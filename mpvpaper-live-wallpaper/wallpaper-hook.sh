#!/bin/bash
# wallpaper-hook.sh - runs after 'caelestia wallpaper -f <image>' sets an image.
# Videos are handled by live-wallpaper.sh directly, NOT through this hook.

# When live-wallpaper.sh calls caelestia just for color extraction, skip everything.
# mpvpaper is already running and we must NOT kill it.
[ "$LIVE_WALLPAPER_COLORS_ONLY" = "1" ] && exit 0

# Kill any active video/scene wallpapers
pkill -f linux-wallpaperengine 2>/dev/null
killall mpvpaper 2>/dev/null
rm -f "$HOME/.local/state/caelestia/wallpaper/is_live_wallpaper_active"

monitors=$(hyprctl monitors -j | jq -r '.[].name')
base_name=$(basename "$WALLPAPER_PATH")
dir_name=$(dirname "$WALLPAPER_PATH")
SHELL_CONF="$HOME/.config/caelestia/shell.json"

if [[ "$base_name" == "preview.jpg" || "$base_name" == "preview.png" || "$base_name" == "preview.gif" ]]; then
    # Wallpaper Engine scene: disable built-in wallpaper, launch linux-wallpaperengine
    if [ -f "$dir_name/project.json" ]; then
        tmp=$(mktemp)
        jq '.background.wallpaperEnabled = false' "$SHELL_CONF" > "$tmp" && cat "$tmp" > "$SHELL_CONF" && rm -f "$tmp"
        args=""
        for mon in $monitors; do
            args="$args --screen-root $mon --bg $dir_name"
        done
        linux-wallpaperengine $args &
    fi
else
    # Standard image: re-enable Caelestia's built-in wallpaper display
    tmp=$(mktemp)
    jq '.background.wallpaperEnabled = true' "$SHELL_CONF" > "$tmp" && cat "$tmp" > "$SHELL_CONF" && rm -f "$tmp"
fi

