#!/usr/bin/env bash
# Nexus Night Mode — install script for Caelestia shell
set -e

CAELESTIA_SRC="${CAELESTIA_SRC:-/etc/xdg/quickshell/caelestia}"
SHELL_JSON="$HOME/.config/caelestia/shell.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}  →${RESET} $*"; }
success() { echo -e "${GREEN}  ✓${RESET} $*"; }
warn()    { echo -e "${YELLOW}  !${RESET} $*"; }
die()     { echo -e "${RED}  ✗ ERROR:${RESET} $*"; exit 1; }

echo -e "\n${BOLD}  🌙 Nexus Night Mode Installer${RESET}\n"

info "Checking for hyprsunset..."
command -v hyprsunset &>/dev/null || die "hyprsunset not found. Install it first (see README)."
success "hyprsunset found"

info "Looking for caelestia at ${CAELESTIA_SRC}..."
[[ -d "$CAELESTIA_SRC" ]] || die "Caelestia not found at $CAELESTIA_SRC. Set CAELESTIA_SRC= and retry."
success "Caelestia found"

info "Installing QML files (sudo required)..."
sudo cp "$SCRIPT_DIR/files/HyprSunset.qml"       "$CAELESTIA_SRC/services/HyprSunset.qml"
sudo cp "$SCRIPT_DIR/files/ServiceLoader.qml"     "$CAELESTIA_SRC/modules/ServiceLoader.qml"
sudo cp "$SCRIPT_DIR/files/Toggles.qml"           "$CAELESTIA_SRC/modules/utilities/cards/Toggles.qml"
sudo cp "$SCRIPT_DIR/files/UtilitiesPanel.qml"    "$CAELESTIA_SRC/modules/nexus/pages/panels/UtilitiesPanel.qml"
success "QML files installed"

CAELESTIA_GITDIR=""
for d in "$HOME/caelestia" "$HOME/.local/share/caelestia"; do
    [[ -f "$d/CMakeLists.txt" ]] && CAELESTIA_GITDIR="$d" && break
done

if [[ -n "$CAELESTIA_GITDIR" ]]; then
    info "Found source at $CAELESTIA_GITDIR — rebuilding plugin..."
    sudo cp "$SCRIPT_DIR/files/utilitiesconfig.hpp" \
        "$CAELESTIA_GITDIR/plugin/src/Caelestia/Config/utilitiesconfig.hpp"
    command -v direnv &>/dev/null && direnv block "$CAELESTIA_GITDIR" 2>/dev/null || true
    CXX_BIN=$(command -v g++ 2>/dev/null || command -v clang++ 2>/dev/null)
    [[ -z "$CXX_BIN" ]] && die "No C++ compiler (install gcc or clang)"
    rm -rf "$CAELESTIA_GITDIR/build"
    cmake -S "$CAELESTIA_GITDIR" -B "$CAELESTIA_GITDIR/build" -G Ninja \
        -DCMAKE_CXX_COMPILER="$CXX_BIN" \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DVERSION=0.0.1 -DENABLE_MODULES=plugin \
        -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
    cmake --build "$CAELESTIA_GITDIR/build" -j"$(nproc)"
    sudo cmake --install "$CAELESTIA_GITDIR/build"
    command -v direnv &>/dev/null && direnv allow "$CAELESTIA_GITDIR" 2>/dev/null || true
    success "Plugin rebuilt and installed"
else
    warn "Caelestia source not found — skipping plugin rebuild."
    warn "If the toggle doesn't appear, see README for manual plugin steps."
fi

info "Patching shell.json..."
if [[ -f "$SHELL_JSON" ]]; then
    python3 -c "
import json
data = json.load(open('$SHELL_JSON'))
qt = data.get('utilities', {}).get('quickToggles', [])
if not any(e.get('id') == 'nightMode' for e in qt):
    qt.append({'id': 'nightMode', 'enabled': True})
    data.setdefault('utilities', {})['quickToggles'] = qt
    json.dump(data, open('$SHELL_JSON', 'w'), indent=2)
" && success "shell.json patched" || warn "Could not patch shell.json — add manually (see README)"
else
    warn "shell.json not found — nightMode will appear after first launch"
fi

echo -e "\n${GREEN}${BOLD}  🌙 Done! Restart Caelestia to activate Night Mode.${RESET}\n"
