#!/bin/bash
# dynamic-transcoder.sh
# Dynamically detects system resolution and transcodes wallpapers to perfectly fit,
# maximizing quality while minimizing battery and resource consumption.

FFMPEG=/usr/bin/ffmpeg
FFPROBE=/usr/bin/ffprobe
DIR="$HOME/Pictures/Wallpapers/Animated"
ORIG_DIR="$DIR/original"
TARGET_FPS=30 # 30 FPS is the sweet spot for smooth wallpapers without battery drain

# Create original/ subfolder if it doesn't exist
if [ ! -d "$ORIG_DIR" ]; then
    mkdir -p "$ORIG_DIR"
fi

# --- DYNAMIC RESOLUTION DETECTION ---
echo "🔍 Detecting system display capabilities..."
DETECTED_RES=""

if command -v xrandr >/dev/null 2>&1; then
    # Find the largest connected monitor resolution
    DETECTED_RES=$(xrandr | awk '/[0-9]+x[0-9]+/ {print $1}' | grep 'x' | awk -F'x' '{if($1>0 && $2>0) print $1*$2, $1"x"$2}' | sort -nr | head -n1 | awk '{print $2}')
fi

if [ -z "$DETECTED_RES" ]; then
    echo "⚠️  Could not detect display resolution dynamically. Defaulting to 1920x1080."
    SCREEN_W=1920
    SCREEN_H=1080
else
    SCREEN_W=$(echo "$DETECTED_RES" | cut -d'x' -f1)
    SCREEN_H=$(echo "$DETECTED_RES" | cut -d'x' -f2)
    echo "✅ Detected maximum display resolution: ${SCREEN_W}x${SCREEN_H}"
fi

echo ""
echo "=== Dynamic Wallpaper Transcoder ==="
echo "Target : ${SCREEN_W}x${SCREEN_H} @ ${TARGET_FPS}fps (Optimized for battery & quality)"
echo "Dir    : $DIR"
echo "Originals → $ORIG_DIR"
echo ""

total_video=0; skipped_video=0; transcoded_video=0; errors_video=0
total_gif=0;   skipped_gif=0;   converted_gif=0;   errors_gif=0

# ── GIF → MP4 conversion ───────────────────────────────────────────────────────────────
echo "--- GIF Conversion ---"
for f in "$DIR"/*.gif; do
    [ -f "$f" ] || continue
    total_gif=$((total_gif + 1))

    base="${f%.gif}"
    fname="$(basename "$f")"
    mp4_out="${base}.mp4"

    if [ -f "$mp4_out" ] && [ "$mp4_out" -nt "$f" ]; then
        echo "  ✓ SKIP (MP4 exists): $(basename "$f")"
        skipped_gif=$((skipped_gif + 1))
        continue
    fi

    orig_gif="$ORIG_DIR/${fname%.gif}.original.gif"
    if [ -f "$orig_gif" ]; then
        echo "  ✓ SKIP (original saved): $fname"
        skipped_gif=$((skipped_gif + 1))
        continue
    fi

    echo ""
    echo "  🎞  CONVERT GIF: $(basename "$f")"

    tmp_out="${base}.tmp_gif.mp4"
    palette_tmp="${base}.tmp_palette.png"
    success=0

    # Pass 1
    "$FFMPEG" -y -i "$f" \
        -vf "palettegen=max_colors=256:stats_mode=diff" \
        -hide_banner -loglevel error -stats \
        "$palette_tmp"
    echo ""
    if [ $? -eq 0 ]; then
        # Pass 2
        "$FFMPEG" -y -i "$f" -i "$palette_tmp" \
            -lavfi "paletteuse=dither=bayer:bayer_scale=5" \
            -c:v libx264 -preset slow -crf 15 \
            -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" \
            -movflags +faststart -an \
            -hide_banner -loglevel error -stats \
            "$tmp_out"
        echo ""
        if [ $? -eq 0 ] && [ -s "$tmp_out" ]; then
            success=1
        fi
        rm -f "$palette_tmp"
    fi

    if [ "$success" -eq 0 ]; then
        rm -f "$tmp_out" "$palette_tmp"
        "$FFMPEG" -y -i "$f" \
            -c:v libx264 -preset slow -crf 15 \
            -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" \
            -movflags +faststart -an \
            -hide_banner -loglevel error -stats \
            "$tmp_out"
        echo ""
        if [ $? -eq 0 ] && [ -s "$tmp_out" ]; then
            success=1
        fi
    fi

    if [ "$success" -eq 1 ]; then
        mv "$tmp_out" "$mp4_out"
        orig_dest="$ORIG_DIR/${fname%.gif}.original.gif"
        mv "$f" "$orig_dest"
        old_size=$(du -sh "$orig_dest" | cut -f1)
        new_size=$(du -sh "$mp4_out" | cut -f1)
        echo "     ✅ GIF → MP4: $old_size → $new_size"
        echo "     (original saved as: original/${fname%.gif}.original.gif)"
        converted_gif=$((converted_gif + 1))
    else
        rm -f "$tmp_out" "$palette_tmp"
        echo "     ❌ GIF conversion failed: $(basename "$f")"
        errors_gif=$((errors_gif + 1))
    fi
done

echo ""

# ── Video transcoding ────────────────────────────────────────────────────────
echo "--- Video Transcoding ---"
for f in "$DIR"/*.mp4 "$DIR"/*.webm "$DIR"/*.mkv; do
    [ -f "$f" ] || continue
    [[ "$(dirname "$f")" == "$ORIG_DIR" ]] && continue
    
    fname="$(basename "$f")"
    base_noext="${fname%.*}"
    ext="${fname##*.}"
    gif_orig="$ORIG_DIR/${base_noext}.original.gif"
    [ -f "$gif_orig" ] && continue
    
    orig_saved="$ORIG_DIR/${base_noext}.original.${ext}"
    if [ -f "$orig_saved" ]; then
        echo "  ✓ SKIP (already transcoded, original in original/): $fname"
        skipped_video=$((skipped_video + 1))
        continue
    fi

    total_video=$((total_video + 1))

    read -r width height fps_str < <("$FFPROBE" -v quiet -select_streams v:0 \
        -show_entries stream=width,height,avg_frame_rate \
        -of csv=p=0 "$f" 2>/dev/null | tr ',' ' ' | head -1)

    if [ -z "$width" ] || [ "$width" = "0" ]; then
        echo "  ⚠ SKIP (can't read): $(basename "$f")"
        skipped_video=$((skipped_video + 1))
        continue
    fi

    fps=0
    if [[ "$fps_str" =~ ^([0-9]+)/([0-9]+)$ ]]; then
        fps=$(( ${BASH_REMATCH[1]} / ${BASH_REMATCH[2]} ))
    elif [[ "$fps_str" =~ ^[0-9]+$ ]]; then
        fps=$fps_str
    fi

    if [ $(( width * SCREEN_H )) -gt $(( height * SCREEN_W )) ]; then
        new_w=$SCREEN_W
        new_h=$(( height * SCREEN_W / width ))
        new_h=$(( (new_h + 1) / 2 * 2 ))
    else
        new_h=$SCREEN_H
        new_w=$(( width * SCREEN_H / height ))
        new_w=$(( (new_w + 1) / 2 * 2 ))
    fi

    needs_resize=0
    needs_fps_cap=0
    [ "$new_w" -ne "$width" ] || [ "$new_h" -ne "$height" ] && needs_resize=1
    [ "$fps" -gt "$TARGET_FPS" ] && needs_fps_cap=1

    if [ "$needs_resize" -eq 0 ] && [ "$needs_fps_cap" -eq 0 ]; then
        echo "  ✓ OK  (${width}x${height} @ ${fps}fps): $(basename "$f")"
        skipped_video=$((skipped_video + 1))
        continue
    fi

    reason=""
    [ "$needs_resize" -eq 1 ] && reason="${reason}resize "
    [ "$needs_fps_cap" -eq 1 ] && reason="${reason}fps-cap"

    echo ""
    echo "  🔄 TRANSCODE (${reason// /,}): $fname"
    echo "     ${width}x${height}@${fps}fps → ${new_w}x${new_h}@${TARGET_FPS}fps"

    out="${f%.*}.tmp_transcode.mp4"
    success=0

    # PATH A: GPU pipeline
    "$FFMPEG" -y \
        -hwaccel cuda \
        -hwaccel_output_format cuda \
        -i "$f" \
        -vf "scale_cuda=${new_w}:${new_h}:format=yuv420p" \
        -r $TARGET_FPS \
        -c:v h264_nvenc -preset p7 -cq 15 -b:v 0 \
        -an -movflags +faststart \
        -hide_banner -loglevel error -stats \
        "$out"
    echo ""
    if [ $? -eq 0 ] && [ -s "$out" ]; then
        success=1
        echo "     (GPU pipeline: CUDA decode + NVENC encode)"
    fi

    # PATH B: CPU decode + GPU encode
    if [ "$success" -eq 0 ]; then
        echo "     ↳ GPU pipeline failed → CPU decode + NVENC fallback..."
        rm -f "$out"
        "$FFMPEG" -y \
            -i "$f" \
            -vf "scale=${new_w}:${new_h}:flags=lanczos" \
            -r $TARGET_FPS \
            -c:v h264_nvenc -preset p7 -cq 15 -b:v 0 \
            -an -movflags +faststart \
            -hide_banner -loglevel error -stats \
            "$out"
        echo ""
        if [ $? -eq 0 ] && [ -s "$out" ]; then
            success=1
            echo "     (CPU decode + NVENC encode)"
        fi
    fi

    # PATH C: Pure software encode
    if [ "$success" -eq 0 ]; then
        echo "     ↳ NVENC failed → pure software fallback (slow but reliable)..."
        rm -f "$out"
        "$FFMPEG" -y \
            -i "$f" \
            -vf "scale=${new_w}:${new_h}:flags=lanczos" \
            -r $TARGET_FPS \
            -c:v libx264 -preset slow -crf 16 \
            -an -movflags +faststart \
            -hide_banner -loglevel error -stats \
            "$out"
        echo ""
        if [ $? -eq 0 ] && [ -s "$out" ]; then
            success=1
            echo "     (software encode: libx264)"
        fi
    fi

    if [ "$success" -eq 1 ]; then
        orig_dest="$ORIG_DIR/${base_noext}.original.${ext}"
        mv "$f" "$orig_dest"
        mv "$out" "$f"
        old_size=$(du -sh "$orig_dest" | cut -f1)
        new_size=$(du -sh "$f" | cut -f1)
        echo "     ✅ Done: $old_size → $new_size"
        echo "     (original saved as: original/${base_noext}.original.${ext})"
        transcoded_video=$((transcoded_video + 1))
    else
        echo "     ❌ All paths failed, keeping original"
        rm -f "$out"
        errors_video=$((errors_video + 1))
    fi
done

echo ""
echo "=== Summary ==="
echo "  Videos : $total_video total | $transcoded_video transcoded | $skipped_video skipped | $errors_video errors"
echo "  GIFs   : $total_gif total   | $converted_gif converted    | $skipped_gif skipped   | $errors_gif errors"
echo ""
if [ "$transcoded_video" -gt 0 ] || [ "$converted_gif" -gt 0 ]; then
    echo "Originals saved in: $ORIG_DIR"
    echo "Delete originals when satisfied with results:"
    echo "  rm -rf \"$ORIG_DIR\""
fi
