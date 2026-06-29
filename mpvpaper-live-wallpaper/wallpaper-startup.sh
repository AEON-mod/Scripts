#!/bin/bash
if [ -f ~/.local/state/caelestia/wallpaper/is_live_wallpaper_active ] && [ -f ~/.local/state/caelestia/wallpaper/current_live_wallpaper.txt ]; then
    VIDEO=$(cat ~/.local/state/caelestia/wallpaper/current_live_wallpaper.txt)
    ~/.config/hypr/scripts/live-wallpaper.sh "$VIDEO"
elif [ -f ~/.local/state/caelestia/wallpaper/path.txt ]; then
    export WALLPAPER_PATH=$(cat ~/.local/state/caelestia/wallpaper/path.txt)
    ~/.config/hypr/scripts/wallpaper-hook.sh
fi
