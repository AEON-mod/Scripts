#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# convert_cursors.sh — Universal cursor theme installer for Linux
#
# Usage:
#   bash convert_cursors.sh                  # process all themes in same folder
#   bash convert_cursors.sh /path/to/theme   # process a specific theme folder
#
# Windows themes (.ani/.cur):  auto-converted via win2xcur, then installed
# X11 themes (cursors/ dir):   installed directly (no conversion needed)
#
# Requires: win2xcur (only for Windows themes)  →  pip install win2xcur
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
ICONS_DIR="$HOME/.local/share/icons"

# ── Colors ────────────────────────────────────────────────────────────────────
GRN='\033[0;32m'; RED='\033[0;31m'; YLW='\033[1;33m'
CYN='\033[0;36m'; BLD='\033[1m'; RST='\033[0m'

log_ok()   { echo -e "  ${GRN}✓${RST}  $*"; }
log_err()  { echo -e "  ${RED}✗${RST}  $*"; }
log_warn() { echo -e "  ${YLW}⚠${RST}  $*"; }
log_info() { echo -e "  ${CYN}→${RST}  $*"; }

# ── Comprehensive X11 cursor alias map ────────────────────────────────────────
# Format: PRIMARY_NAME "alias1 alias2 ..."
# All aliases become symlinks pointing to their primary.
declare -A ALIASES=(
    [default]="left_ptr arrow top_left_arrow center_ptr X_cursor dnd-none"
    [help]="question_arrow whats_this left_ptr_help"
    [progress]="left_ptr_watch half-busy 028006030e0e7ebffc7f7070c0600140"
    [wait]="watch clock"
    [crosshair]="cross diamond_cross tcross fcf1c3c7cd4491d801f1e1c78f100000 zoom-in zoom-out"
    [text]="xterm ibeam"
    [pencil]=""
    [not-allowed]="crossed_circle forbidden circle no-drop"
    [ns-resize]="v_double_arrow size_ver sb_v_double_arrow top_side bottom_side n-resize s-resize row-resize 00008160000006810000408080010102"
    [ew-resize]="h_double_arrow size_hor sb_h_double_arrow left_side right_side e-resize w-resize col-resize"
    [nwse-resize]="size_fdiag top_left_corner bottom_right_corner nw-resize se-resize c7088f0f3e6c8088236ef8e1e3e70000"
    [nesw-resize]="size_bdiag top_right_corner bottom_left_corner ne-resize sw-resize 9d800788f1b08800ae810202380a0822"
    [all-scroll]="fleur move size_all grabbing grab dnd-move 04b16c0a5bca0ab4d02d5de7de0a7bc8"
    [up-arrow]="sb_up_arrow"
    [pointer]="hand1 hand2 pointing_hand openhand e29285e634086352946a0e7090d73106"
    [person]="default_person"
    [pin]="default_pin"
    [cell]=""
)

# ── Windows filename → X11 primary name ──────────────────────────────────────
declare -A WIN_MAP=(
    # Standard PascalCase (Arlecchino, Jinhsi, most themes)
    [Normal]=default      [Help]=help         [Working]=progress
    [Busy]=wait           [Precision]=crosshair [Text]=text
    [Handwriting]=pencil  [Unavailable]=not-allowed
    [Vertical]=ns-resize  [Horizontal]=ew-resize
    [Diagonal1]=nwse-resize [Diagonal2]=nesw-resize
    [Move]=all-scroll     [Alternate]=up-arrow  [Link]=pointer
    [Person]=person       [Pin]=pin
    # Lowercase variants (Ellen-Joe-Chibi style)
    [pointer]=default     [help]=help         [working]=progress
    [busy]=wait           [cross]=crosshair   [text]=text
    [handwriting]=pencil  [unavailable]=not-allowed
    [vert]=ns-resize      [horz]=ew-resize
    [dgn1]=nwse-resize    [dgn2]=nesw-resize
    [move]=all-scroll     [alternate]=up-arrow  [link]=pointer
    [loc]=cell            [person]=person
    # More lowercase flat-layout names (Glitch style)
    [arrow]=default       [hand]=pointer      [hori]=ew-resize
    [diag1]=nwse-resize   [diag2]=nesw-resize [no]=not-allowed
    [pin]=pin             [pen]=pencil
    [start]=progress      [start1]=progress   [start2]=progress   [start3]=progress
    [wait]=wait           [wait1]=wait          [wait2]=wait
    [loading]=progress    [loading1]=progress
    [text2]=text          [arrow2]=default    [arrow3]=default
    [help2]=help          [help3]=help
    [032]=wait            [064]=wait
    # Other common Windows names
    [Arrow]=default       [Wait]=wait         [IBeam]=text
    [SizeNS]=ns-resize    [SizeWE]=ew-resize
    [SizeNWSE]=nwse-resize [SizeNESW]=nesw-resize
    [SizeAll]=all-scroll  [No]=not-allowed    [AppStarting]=progress
    [Hand]=pointer        [Crosshair]=crosshair
    [NWPen]=pencil        [Pin]=pin           [Person]=person
)

# ── Make symlinks for a primary cursor ───────────────────────────────────────
make_symlinks() {
    local cursors_dir="$1"
    local primary="$2"
    [[ -f "$cursors_dir/$primary" ]] || return 0
    local aliases="${ALIASES[$primary]:-}"
    [[ -z "$aliases" ]] && return 0
    for alias in $aliases; do
        [[ "$alias" == "$primary" ]] && continue
        rm -f "$cursors_dir/$alias"
        ln -sf "$primary" "$cursors_dir/$alias"
    done
}

# ── Write theme metadata files ────────────────────────────────────────────────
write_theme_meta() {
    local dest="$1"
    local theme_name="$2"
    cat > "$dest/index.theme" <<EOF
[Icon Theme]
Name=$theme_name
Comment=Cursor theme installed by convert_cursors.sh
EOF
    cat > "$dest/cursor.theme" <<EOF
[Icon Theme]
Name=$theme_name
EOF
}

# ── Install a Windows cursor theme (.ani / .cur) ──────────────────────────────
install_windows_theme() {
    local theme_name="$1"
    local src_dir="$2"       # folder containing *.ani / *.cur files
    local dest="$ICONS_DIR/$theme_name"
    local cursors_dir="$dest/cursors"

    if ! command -v win2xcur &>/dev/null; then
        log_err "win2xcur not found — install with: pip install win2xcur"
        return 1
    fi

    rm -rf "$dest"
    mkdir -p "$cursors_dir"
    write_theme_meta "$dest" "$theme_name"

    local ok=0 fail=0 skip=0

    for src in "$src_dir"/*.ani "$src_dir"/*.cur "$src_dir"/*.ANI "$src_dir"/*.CUR; do
        [[ -f "$src" ]] || continue
        local stem
        stem="$(basename "$src")"
        stem="${stem%.*}"

        # Lookup X11 name
        local x11_name="${WIN_MAP[$stem]:-}"
        if [[ -z "$x11_name" ]]; then
            log_warn "$stem — no mapping found, skipping"
            (( skip++ )) || true
            continue
        fi

        # Convert via win2xcur into a temp dir, then copy
        local tmp_dir
        tmp_dir="$(mktemp -d)"
        if win2xcur -o "$tmp_dir" "$src" &>/dev/null; then
            local converted="$tmp_dir/$stem"
            if [[ -f "$converted" ]]; then
                cp "$converted" "$cursors_dir/$x11_name"
                log_ok "$stem → $x11_name"
                make_symlinks "$cursors_dir" "$x11_name"
                (( ok++ )) || true
            else
                log_err "$stem — win2xcur produced no output"
                (( fail++ )) || true
            fi
        else
            log_err "$stem — win2xcur conversion failed"
            (( fail++ )) || true
        fi
        rm -rf "$tmp_dir"
    done

    echo -e "  ──────────────────────────────"
    log_ok "Done: ${GRN}$ok converted${RST}, ${RED}$fail failed${RST}, ${YLW}$skip skipped${RST}"
    log_ok "Installed → $dest"
}

# ── Install a native X11 cursor theme (already has cursors/ dir) ──────────────
install_x11_theme() {
    local theme_name="$1"
    local src_cursors_dir="$2"   # the cursors/ subfolder
    local dest="$ICONS_DIR/$theme_name"
    local cursors_dir="$dest/cursors"

    rm -rf "$dest"
    mkdir -p "$cursors_dir"
    write_theme_meta "$dest" "$theme_name"

    # Copy all cursor files
    local count=0
    for f in "$src_cursors_dir"/*; do
        [[ -f "$f" && ! -L "$f" ]] || continue
        cp "$f" "$cursors_dir/"
        (( count++ )) || true
    done

    # Add any missing standard aliases
    for primary in "${!ALIASES[@]}"; do
        make_symlinks "$cursors_dir" "$primary"
    done

    log_ok "Copied $count cursor files"
    log_ok "Installed → $dest"
}

# ── Detect and process a single theme folder ──────────────────────────────────
process_theme() {
    local src="$1"
    local theme_name
    theme_name="$(basename "$src")"

    # Skip: zip files, the script itself, existing icons dir
    [[ -f "$src" ]] && return 0
    [[ "$src" == *".zip" || "$src" == *".7z" || "$src" == *".tar"* ]] && return 0

    echo -e "\n${BLD}━━━ $theme_name ━━━${RST}"

    # ── Case 1: Has a cursors/ subdirectory → native X11 theme ──
    if [[ -d "$src/cursors" ]]; then
        log_info "Detected: native X11 theme"
        install_x11_theme "$theme_name" "$src/cursors"
        return 0
    fi

    # ── Case 2: .ani/.cur directly in the root folder (check before subfolder) ──
    if ls "$src"/*.ani &>/dev/null 2>&1 || ls "$src"/*.cur &>/dev/null 2>&1 \
    || ls "$src"/*.ANI &>/dev/null 2>&1 || ls "$src"/*.CUR &>/dev/null 2>&1; then
        log_info "Detected: Windows cursor theme (flat layout)"
        install_windows_theme "$theme_name" "$src"
        return 0
    fi

    # ── Case 3: Has a Cursors/ subfolder (Windows pack with subfolder) ──
    local cursors_subdir=""
    for sub in "$src"/*/; do
        # Skip tmp/ and other non-cursor folders
        local subname
        subname="$(basename "$sub")"
        [[ "$subname" == "tmp" || "$subname" == "Gifs" || "$subname" == "Static" || "$subname" == "MacOS" ]] && continue
        if ls "$sub"*.ani &>/dev/null 2>&1 || ls "$sub"*.cur &>/dev/null 2>&1 \
        || ls "$sub"*.ANI &>/dev/null 2>&1 || ls "$sub"*.CUR &>/dev/null 2>&1; then
            cursors_subdir="$sub"
            break
        fi
    done

    if [[ -n "$cursors_subdir" ]]; then
        log_info "Detected: Windows cursor theme (subfolder: $(basename "$cursors_subdir"))"
        install_windows_theme "$theme_name" "$cursors_subdir"
        return 0
    fi

    log_warn "Cannot detect cursor format — skipping"
}

# ── Also patch already-installed themes with missing aliases ──────────────────
patch_installed() {
    local theme_name="$1"
    local cursors_dir="$ICONS_DIR/$theme_name/cursors"
    [[ -d "$cursors_dir" ]] || return 0
    echo -e "\n${BLD}━━━ Patching symlinks: $theme_name ━━━${RST}"
    for primary in "${!ALIASES[@]}"; do
        make_symlinks "$cursors_dir" "$primary"
    done
    log_ok "Aliases up to date"
}

# ── Main ──────────────────────────────────────────────────────────────────────
mkdir -p "$ICONS_DIR"

echo -e "\n${BLD}${CYN}═══ Universal Cursor Theme Installer ═══${RST}"

if [[ $# -gt 0 ]]; then
    # Specific path(s) passed as arguments
    for arg in "$@"; do
        process_theme "$arg"
    done
else
    # Scan all subdirectories next to this script
    # (skip: the script itself and any already-installed themes in ICONS_DIR)
    found=0
    for dir in "$SCRIPT_DIR"/*/; do
        [[ -d "$dir" ]] || continue
        process_theme "$dir"
        (( found++ )) || true
    done
    [[ $found -eq 0 ]] && echo -e "\n${YLW}No theme folders found next to this script.${RST}"
fi

echo -e "\n${BLD}${GRN}═══ All done! ═══${RST}"
echo ""
echo "Apply a theme:"
echo -e "  ${CYN}hyprctl setcursor <ThemeName> 24${RST}"
echo ""
echo "Make it permanent (add to ~/.config/hypr/hyprland.conf):"
echo -e "  ${CYN}env = XCURSOR_THEME,<ThemeName>"
echo -e "  env = XCURSOR_SIZE,24"
echo -e "  exec-once = hyprctl setcursor <ThemeName> 24${RST}"
