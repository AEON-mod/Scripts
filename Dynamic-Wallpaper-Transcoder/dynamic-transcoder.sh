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

echo "🔍 Detecting system display capabilities..."
DETECTED_RES=()

if command -v xrandr >/dev/null 2>&1; then
    # Grab active resolutions using `*` marker, then sort unique descending
    mapfile -t DETECTED_RES < <(xrandr | awk '/\*/ {print $1}' | grep 'x' | sort -u -t'x' -k1,1nr -k2,2nr)
fi

if [ ${#DETECTED_RES[@]} -eq 0 ]; then
    echo "⚠️  Could not detect display resolution dynamically. Defaulting to 1920x1080."
    DETECTED_RES=("1920x1080")
fi

SELECTED_RES=()
DO_ALL=0

if [ ${#DETECTED_RES[@]} -eq 1 ]; then
    echo "✅ Detected display resolution: ${DETECTED_RES[0]}"
    SELECTED_RES=("${DETECTED_RES[0]}")
else
    echo "🖥️  Multiple different monitor resolutions detected!"
    for i in "${!DETECTED_RES[@]}"; do
        echo "  $((i+1))) Target ${DETECTED_RES[$i]}"
    done
    ALL_OPT=$(( ${#DETECTED_RES[@]} + 1 ))
    echo "  $ALL_OPT) All of them (creates resolution-specific folders)"
    
    while true; do
        read -p "Choose an option [1-$ALL_OPT]: " choice
        if [[ "$choice" =~ ^[0-9]+$ ]]; then
            if [ "$choice" -ge 1 ] && [ "$choice" -le ${#DETECTED_RES[@]} ]; then
                idx=$((choice-1))
                SELECTED_RES=("${DETECTED_RES[$idx]}")
                echo "✅ Selected: ${SELECTED_RES[0]}"
                break
            elif [ "$choice" -eq "$ALL_OPT" ]; then
                SELECTED_RES=("${DETECTED_RES[@]}")
                DO_ALL=1
                echo "✅ Selected ALL. Will output to subfolders."
                break
            fi
        fi
        echo "❌ Invalid choice."
    done
fi

echo ""
echo "=== Dynamic Wallpaper Transcoder ==="
if [ "$DO_ALL" -eq 1 ]; then
    echo "Target : Multiple Resolutions @ ${TARGET_FPS}fps"
else
    echo "Target : ${SELECTED_RES[0]} @ ${TARGET_FPS}fps"
fi
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

    orig_gif="$ORIG_DIR/${fname%.gif}.original.gif"
    if [ -f "$orig_gif" ]; then
        echo "  ✓ SKIP (original saved): $fname"
        skipped_gif=$((skipped_gif + 1))
        continue
    fi
    
    # If not DO_ALL, check if MP4 exists
    if [ "$DO_ALL" -eq 0 ] && [ -f "$mp4_out" ] && [ "$mp4_out" -nt "$f" ]; then
        echo "  ✓ SKIP (MP4 exists): $fname"
        skipped_gif=$((skipped_gif + 1))
        continue
    fi

    # If DO_ALL, check if MP4 exists in ALL folders
    if [ "$DO_ALL" -eq 1 ]; then
        all_exist=1
        for res in "${SELECTED_RES[@]}"; do
            if [ ! -f "$DIR/$res/$mp4_out" ]; then
                all_exist=0
                break
            fi
        done
        if [ "$all_exist" -eq 1 ]; then
            echo "  ✓ SKIP (MP4 exists in all folders): $fname"
            skipped_gif=$((skipped_gif + 1))
            continue
        fi
    fi

    echo ""
    echo "  🎞  CONVERT GIF: $fname"

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
        orig_dest="$ORIG_DIR/${fname%.gif}.original.gif"
        mv "$f" "$orig_dest"
        
        old_size=$(du -sh "$orig_dest" | cut -f1)
        new_size=$(du -sh "$tmp_out" | cut -f1)
        
        if [ "$DO_ALL" -eq 1 ]; then
            for res in "${SELECTED_RES[@]}"; do
                mkdir -p "$DIR/$res"
                cp "$tmp_out" "$DIR/$res/$mp4_out"
                echo "     ✅ GIF → MP4 ($res): $old_size → $new_size"
            done
            rm "$tmp_out"
        else
            mv "$tmp_out" "$mp4_out"
            echo "     ✅ GIF → MP4: $old_size → $new_size"
        fi
        
        echo "     (original saved as: original/${fname%.gif}.original.gif)"
        converted_gif=$((converted_gif + 1))
    else
        rm -f "$tmp_out" "$palette_tmp"
        echo "     ❌ GIF conversion failed: $fname"
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

    # If not DO_ALL and orig_saved exists, it means already transcoded in-place
    if [ "$DO_ALL" -eq 0 ] && [ -f "$orig_saved" ]; then
        echo "  ✓ SKIP (already transcoded, original in original/): $fname"
        skipped_video=$((skipped_video + 1))
        continue
    fi

    total_video=$((total_video + 1))
    moved_to_orig=0
    transcoded_any=0
    
    for res in "${SELECTED_RES[@]}"; do
        SCREEN_W=$(echo "$res" | cut -d'x' -f1)
        SCREEN_H=$(echo "$res" | cut -d'x' -f2)
        
        if [ "$DO_ALL" -eq 1 ]; then
            target_dir="$DIR/$res"
            mkdir -p "$target_dir"
            out_final="$target_dir/$fname"
        else
            out_final="$f"
        fi
        
        # Check if already exists in target resolution
        if [ "$DO_ALL" -eq 1 ] && [ -f "$out_final" ]; then
            echo "  ✓ SKIP (already exists in $res/): $fname"
            continue
        fi
        
        # Determine Source File (read from original/ if already backed up)
        if [ -f "$orig_saved" ] && [ ! -f "$f" ]; then
            src_file="$orig_saved"
        else
            src_file="$f"
        fi
        
        # Get dimensions
        read -r width height fps_str < <("$FFPROBE" -v quiet -select_streams v:0 \
            -show_entries stream=width,height,avg_frame_rate \
            -of csv=p=0 "$src_file" 2>/dev/null | tr ',' ' ' | head -1)

        if [ -z "$width" ] || [ "$width" = "0" ]; then
            echo "  ⚠ SKIP (can't read): $fname"
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
            echo "  ✓ OK  (${width}x${height} @ ${fps}fps) matches $res: $fname"
            if [ "$DO_ALL" -eq 1 ]; then
                cp "$src_file" "$out_final"
            fi
            continue
        fi

        reason=""
        [ "$needs_resize" -eq 1 ] && reason="${reason}resize "
        [ "$needs_fps_cap" -eq 1 ] && reason="${reason}fps-cap"

        echo ""
        echo "  🔄 TRANSCODE ($res) (${reason// /,}): $fname"
        echo "     ${width}x${height}@${fps}fps → ${new_w}x${new_h}@${TARGET_FPS}fps"

        out_tmp="${f%.*}.tmp_transcode_${SCREEN_W}.mp4"
        success=0

        # PATH A: GPU pipeline
        "$FFMPEG" -y \
            -hwaccel cuda \
            -hwaccel_output_format cuda \
            -i "$src_file" \
            -vf "scale_cuda=${new_w}:${new_h}:format=yuv420p" \
            -r $TARGET_FPS \
            -c:v h264_nvenc -preset p7 -cq 15 -b:v 0 \
            -an -movflags +faststart \
            -hide_banner -loglevel error -stats \
            "$out_tmp"
        echo ""
        if [ $? -eq 0 ] && [ -s "$out_tmp" ]; then
            success=1
            echo "     (GPU pipeline: CUDA decode + NVENC encode)"
        fi

        # PATH B: CPU decode + GPU encode
        if [ "$success" -eq 0 ]; then
            echo "     ↳ GPU pipeline failed → CPU decode + NVENC fallback..."
            rm -f "$out_tmp"
            "$FFMPEG" -y \
                -i "$src_file" \
                -vf "scale=${new_w}:${new_h}:flags=lanczos" \
                -r $TARGET_FPS \
                -c:v h264_nvenc -preset p7 -cq 15 -b:v 0 \
                -an -movflags +faststart \
                -hide_banner -loglevel error -stats \
                "$out_tmp"
            echo ""
            if [ $? -eq 0 ] && [ -s "$out_tmp" ]; then
                success=1
                echo "     (CPU decode + NVENC encode)"
            fi
        fi

        # PATH C: Pure software encode
        if [ "$success" -eq 0 ]; then
            echo "     ↳ NVENC failed → pure software fallback (slow but reliable)..."
            rm -f "$out_tmp"
            "$FFMPEG" -y \
                -i "$src_file" \
                -vf "scale=${new_w}:${new_h}:flags=lanczos" \
                -r $TARGET_FPS \
                -c:v libx264 -preset slow -crf 16 \
                -an -movflags +faststart \
                -hide_banner -loglevel error -stats \
                "$out_tmp"
            echo ""
            if [ $? -eq 0 ] && [ -s "$out_tmp" ]; then
                success=1
                echo "     (software encode: libx264)"
            fi
        fi

        if [ "$success" -eq 1 ]; then
            if [ "$moved_to_orig" -eq 0 ] && [ -f "$f" ]; then
                mv "$f" "$orig_saved"
                moved_to_orig=1
                echo "     (original saved as: original/${base_noext}.original.${ext})"
            fi
            
            mv "$out_tmp" "$out_final"
            
            old_size=$(du -sh "$orig_saved" | cut -f1)
            new_size=$(du -sh "$out_final" | cut -f1)
            echo "     ✅ Done ($res): $old_size → $new_size"
            transcoded_any=1
        else
            echo "     ❌ All paths failed for $res"
            rm -f "$out_tmp"
            errors_video=$((errors_video + 1))
        fi
    done
    
    if [ "$transcoded_any" -eq 1 ]; then
        transcoded_video=$((transcoded_video + 1))
    fi

    # Clean up the root file if we are doing DO_ALL and successfully processed
    if [ "$DO_ALL" -eq 1 ] && [ -f "$f" ]; then
        mv "$f" "$orig_saved"
    fi
done

echo ""
echo "=== Summary ==="
echo "  Videos : $total_video processed | $transcoded_video had transcode tasks | $errors_video errors"
echo "  GIFs   : $total_gif total   | $converted_gif converted    | $skipped_gif skipped   | $errors_gif errors"
echo ""
