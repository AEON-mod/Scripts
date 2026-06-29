#!/bin/bash
# transcode-wallpapers.sh
# Transcodes 4K/high-res wallpaper videos to 1080p @ 30fps using GPU (NVENC)
# so mpvpaper can hardware-decode them efficiently on a 1080p screen.
#
# WHY:
#   RTX 4050 Laptop + 1080p screen — playing 4K is 4x wasted decode work.
#   30fps cap: mpvpaper copies frames at display refresh; 60fps = 2x the copy work.
#   After transcoding: ~20% CPU, zero dropped frames, stable temps (~65°C).
#
# APPROACH (two-path):
#   Path A: hwaccel cuda + scale_cuda + h264_nvenc  — full GPU, fastest
#           Works on 4K H.264/HEVC. May fail on some 1440p sources.
#   Path B: software decode + scale CPU + h264_nvenc — universal fallback
#           Slower to decode but always works. Still GPU-encodes via NVENC.
#
# Uses /usr/bin/ffmpeg directly (bypasses the firejail wrapper at /usr/local/bin/ffmpeg)
#
# Output: originals renamed to .orig.<ext>, new 1080p30 files replace them.
# Re-run anytime you add new wallpapers — already-converted files are skipped.

DIR="/home/aeon/Pictures/Wallpapers/live-wallpaper"
SCREEN_W=1920
SCREEN_H=1080

echo "=== Wallpaper Video Transcoder ==="
echo "Target: ${SCREEN_W}x${SCREEN_H} (your screen resolution)"
echo ""

total=0
skipped=0
transcoded=0
errors=0

for f in "$DIR"/*.mp4 "$DIR"/*.webm "$DIR"/*.mkv; do
    [ -f "$f" ] || continue
    # Skip already-transcoded originals (marked with .orig)
    [[ "$f" == *.orig.* ]] && continue

    total=$((total + 1))

    # Get dimensions (use /usr/bin/ffprobe — /usr/local/bin is firejailed)
    read -r width height < <(/usr/bin/ffprobe -v quiet -select_streams v:0 \
        -show_entries stream=width,height \
        -of csv=p=0 "$f" 2>/dev/null | tr ',' ' ' | head -1)

    if [ -z "$width" ] || [ "$width" = "0" ]; then
        echo "  ⚠ SKIP (can't read): $(basename "$f")"
        skipped=$((skipped + 1))
        continue
    fi

    # Skip if already at or below screen resolution
    if [ "$width" -le "$SCREEN_W" ] && [ "$height" -le "$SCREEN_H" ]; then
        echo "  ✓ OK  (${width}x${height}): $(basename "$f")"
        skipped=$((skipped + 1))
        continue
    fi

    # Calculate output size — fit within 1920x1080, maintain aspect ratio
    new_w=$width
    new_h=$height
    if [ "$new_w" -gt "$SCREEN_W" ]; then
        new_h=$(( height * SCREEN_W / width ))
        new_h=$(( (new_h + 1) / 2 * 2 ))
        new_w=$SCREEN_W
    fi
    if [ "$new_h" -gt "$SCREEN_H" ]; then
        new_w=$(( width * SCREEN_H / height ))
        new_w=$(( (new_w + 1) / 2 * 2 ))
        new_h=$SCREEN_H
    fi

    echo ""
    echo "  🔄 TRANSCODE: $(basename "$f")"
    echo "     ${width}x${height} → ${new_w}x${new_h} @ 30fps"

    base="${f%.*}"
    ext="${f##*.}"
    out="${base}.tmp_transcode.mp4"
    orig="${base}.orig.${ext}"
    success=0

    # ── PATH A: Full GPU pipeline ─────────────────────────────────────────────
    # cuda hwaccel keeps decoded frames on GPU → scale_cuda resizes on GPU → nvenc encodes.
    # Zero CPU memcpy. Works perfectly for 4K H.264/HEVC sources.
    if /usr/bin/ffmpeg -y \
        -hwaccel cuda \
        -hwaccel_output_format cuda \
        -i "$f" \
        -vf "scale_cuda=${new_w}:${new_h}:format=yuv420p" \
        -r 30 \
        -c:v h264_nvenc -preset p4 -cq 20 -b:v 0 \
        -an -movflags +faststart \
        "$out" 2>&1 | grep -E "^frame=.*speed=|Conversion failed" | tail -1
    then
        [ -s "$out" ] && success=1
    fi

    # ── PATH B: Software decode + NVENC (universal fallback) ─────────────────
    # Slower CPU decode but works on any source format/resolution.
    # GPU still used for encoding via h264_nvenc.
    if [ "$success" -eq 0 ]; then
        echo "     ↳ GPU pipeline failed → using CPU decode + NVENC fallback..."
        rm -f "$out"
        if /usr/bin/ffmpeg -y \
            -i "$f" \
            -vf "scale=${new_w}:${new_h}:flags=lanczos" \
            -r 30 \
            -c:v h264_nvenc -preset p4 -cq 20 -b:v 0 \
            -an -movflags +faststart \
            "$out" 2>&1 | grep -E "^frame=.*speed=|Conversion failed" | tail -1
        then
            [ -s "$out" ] && success=1
        fi
    fi

    # ── Result ────────────────────────────────────────────────────────────────
    if [ "$success" -eq 1 ]; then
        mv "$f" "$orig"
        mv "$out" "${base}.mp4"
        old_size=$(du -sh "$orig" | cut -f1)
        new_size=$(du -sh "${base}.mp4" | cut -f1)
        echo "     ✅ Done: $old_size → $new_size  (original saved as .orig.$ext)"
        transcoded=$((transcoded + 1))
    else
        echo "     ❌ Both paths failed, keeping original"
        rm -f "$out"
        errors=$((errors + 1))
    fi
done

echo ""
echo "=== Done ==="
echo "  Total: $total | Transcoded: $transcoded | Skipped (already OK): $skipped | Errors: $errors"
echo ""
if [ "$transcoded" -gt 0 ]; then
    echo "Originals saved as .orig.* — delete when you're happy:"
    echo "  rm \"$DIR\"/*.orig.*"
fi
