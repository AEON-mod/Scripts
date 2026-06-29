#!/bin/bash
# live-wallpaper.sh — sets a video as wallpaper using mpvpaper directly.
# Does NOT call 'caelestia wallpaper' to avoid triggering the postHook loop.

DIR="$HOME/Pictures/Wallpapers/live-wallpaper"
mkdir -p "$DIR"

STATE_FILE="$HOME/.local/state/caelestia/wallpaper/current_live_wallpaper.txt"
FLAG_FILE="$HOME/.local/state/caelestia/wallpaper/is_live_wallpaper_active"
SHELL_CONF="$HOME/.config/caelestia/shell.json"

# Kill any existing wallpaper processes
killall mpvpaper 2>/dev/null
pkill -f linux-wallpaperengine 2>/dev/null

# Determine which video to play
if [ -z "$1" ]; then
    mapfile -t VIDEOS < <(find "$DIR" -type f \( -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' \) | sort)
    if [ ${#VIDEOS[@]} -eq 0 ]; then
        notify-send "Live Wallpaper" "No videos found in $DIR" 2>/dev/null
        exit 1
    fi

    CURRENT=""
    [ -f "$STATE_FILE" ] && CURRENT=$(cat "$STATE_FILE")

    NEXT_INDEX=0
    for i in "${!VIDEOS[@]}"; do
        if [[ "${VIDEOS[$i]}" == "$CURRENT" ]]; then
            NEXT_INDEX=$(( (i + 1) % ${#VIDEOS[@]} ))
            break
        fi
    done
    VIDEO="${VIDEOS[$NEXT_INDEX]}"
else
    VIDEO="$1"
fi

[ ! -f "$VIDEO" ] && exit 1

# Save state
echo "$VIDEO" > "$STATE_FILE"
touch "$FLAG_FILE"

# Disable Caelestia's built-in wallpaper renderer so video is visible underneath
tmp=$(mktemp)
jq '.background.wallpaperEnabled = false' "$SHELL_CONF" > "$tmp" && cat "$tmp" > "$SHELL_CONF" && rm -f "$tmp"

# Launch mpvpaper:
#   -s                  = auto-stop when wallpaper is fully hidden (most CPU-efficient)
#   hwdec=nvdec-copy    = GPU decode → system RAM copy (only working hwdec with mpvpaper's EGL)
#                         Pure nvdec fails because mpvpaper uses a libmpv EGL surface,
#                         not a native dmabuf surface. nvdec-copy is the correct mode here.
#   hwdec-codecs=all    = remove codec whitelist (handles VP9, AV1, etc.)
#   mute=yes            = silent wallpaper
#   panscan=1.0         = fill screen without black bars (compositor handles scaling)
#   NOTE: NO vf=scale — Wayland compositor scales natively at zero CPU cost
#   NOTE: Videos should be pre-transcoded to 1080p30 via transcode-wallpapers.sh
#         for lowest CPU usage. 4K videos cause 4× extra decode+copy work.
mpvpaper -s -o "loop=yes hwdec=nvdec-copy hwdec-codecs=all mute=yes panscan=1.0" '*' "$VIDEO" &

# Extract a representative frame from the video so caelestia can generate
# the color scheme for widgets (without touching the wallpaper itself).
FRAME_CACHE="$HOME/.cache/caelestia-live-frame.jpg"
ffmpeg -y -ss 5 -i "$VIDEO" -vframes 1 -q:v 3 -vf "scale=512:288" "$FRAME_CACHE" 2>/dev/null \
    || ffmpeg -y -i "$VIDEO" -vframes 1 -q:v 3 -vf "scale=512:288" "$FRAME_CACHE" 2>/dev/null

# Tell caelestia to update the color scheme from that frame.
# LIVE_WALLPAPER_COLORS_ONLY=1 signals wallpaper-hook.sh to skip its
# mpvpaper-killing logic since the video is already playing.
if [ -f "$FRAME_CACHE" ]; then
    LIVE_WALLPAPER_COLORS_ONLY=1 caelestia wallpaper -f "$FRAME_CACHE"
fi
