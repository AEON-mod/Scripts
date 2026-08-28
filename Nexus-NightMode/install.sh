#!/usr/bin/env bash
# Nexus Night Mode - install script for Caelestia shell
set -e

CAELESTIA_SRC="${CAELESTIA_SRC:-/etc/xdg/quickshell/caelestia}"
SHELL_JSON="$HOME/.config/caelestia/shell.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}  ->${RESET} $*"; }
success() { echo -e "${GREEN}  v${RESET} $*"; }
warn()    { echo -e "${YELLOW}  !${RESET} $*"; }
die()     { echo -e "${RED}  x ERROR:${RESET} $*"; exit 1; }

echo -e "\n${BOLD}  🌙 Night Mode Installer${RESET}\n"

info "Checking for hyprsunset..."
command -v hyprsunset &>/dev/null || die "hyprsunset not found. Install it first (see README)."
success "hyprsunset found"

info "Looking for caelestia at ${CAELESTIA_SRC}..."
[[ -d "$CAELESTIA_SRC" ]] || die "Caelestia not found at $CAELESTIA_SRC. Set CAELESTIA_SRC= and retry."
success "Caelestia found"

info "Copying service and patching QML files (sudo required)..."
sudo cp "$SCRIPT_DIR/HyprSunset.qml" "$CAELESTIA_SRC/services/HyprSunset.qml"

sudo python3 - "$CAELESTIA_SRC" << 'PYEOF'
import sys

def insert_after(file_path, search_str, insert_str):
    with open(file_path, 'r') as f:
        content = f.read()
    if insert_str.strip() in content:
        return
    if search_str not in content:
        print(f"Warning: could not find anchor in {file_path}")
        return
    parts = content.split(search_str, 1)
    new_content = parts[0] + search_str + "\n" + insert_str + parts[1]
    with open(file_path, 'w') as f:
        f.write(new_content)

base = sys.argv[1]

# ServiceLoader.qml
insert_after(f"{base}/modules/ServiceLoader.qml", "GameMode;", "        HyprSunset;")

# Toggles.qml
toggle_code = """                DelegateChoice {
                    roleValue: "nightMode"
                    delegate: Toggle {
                        icon: "dark_mode"
                        checked: HyprSunset.active
                        onClicked: HyprSunset.toggle()
                    }
                }"""
insert_after(f"{base}/modules/utilities/cards/Toggles.qml", "onClicked: Notifs.dnd = !Notifs.dnd\n                    }\n                }", toggle_code)

# UtilitiesPanel.qml (ToggleRow)
toggle_row = """
        ToggleRow {
            last: true
            text: qsTr("Night mode")
            subtext: qsTr("Enable blue-light filter via hyprsunset")
            disabled: !Config.utilities.cards.quickToggles
            checked: root.isToggleOn("nightMode")
            onToggled: root.setToggleOn("nightMode", checked)
        }"""
insert_after(f"{base}/modules/nexus/pages/panels/UtilitiesPanel.qml", 'root.setToggleOn("dnd", checked)\n        }', toggle_row)

# UtilitiesPanel.qml (Slider)
slider_code = """
        // Night Mode
        SectionHeader {
            text: qsTr("Night mode")
        }

        SliderRow {
            readonly property int minTemp: 1000
            readonly property int maxTemp: 6500

            first: true
            last: true
            icon: "dark_mode"
            label: qsTr("Color temperature")
            valueLabel: HyprSunset.temperature + qsTr("K")
            value: (HyprSunset.temperature - minTemp) / (maxTemp - minTemp)
            onMoved: v => {
                const temp = Math.round(minTemp + v * (maxTemp - minTemp))
                HyprSunset.start(temp)
            }
        }"""
insert_after(f"{base}/modules/nexus/pages/panels/UtilitiesPanel.qml", 'root.setToggleOn("pipPause", checked)\n        }', slider_code)

# UtilitiesPanel.qml (Import)
insert_after(f"{base}/modules/nexus/pages/panels/UtilitiesPanel.qml", "import qs.modules.nexus.common", "import qs.services")
PYEOF

success "QML files patched successfully"

CAELESTIA_GITDIR=""
for d in "$HOME/caelestia" "$HOME/.local/share/caelestia"; do
    [[ -f "$d/CMakeLists.txt" ]] && CAELESTIA_GITDIR="$d" && break
done

if [[ -n "$CAELESTIA_GITDIR" ]]; then
    info "Found source at $CAELESTIA_GITDIR - patching config and rebuilding plugin..."
    
    python3 - "$CAELESTIA_GITDIR" << 'PYEOF'
import sys
base = sys.argv[1]
p = f"{base}/plugin/src/Caelestia/Config/utilitiesconfig.hpp"
try:
    content = open(p).read()
    if 'LIST_ENTRY(nightMode, true)' not in content:
        content = content.replace('LIST_ENTRY(dnd, true),', 'LIST_ENTRY(dnd, true),\n            LIST_ENTRY(nightMode, true),')
        open(p, 'w').write(content)
except Exception as e:
    print(f"Failed to patch C++ config: {e}")
PYEOF

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
    warn "Caelestia source not found - skipping plugin rebuild."
    warn "If the toggle does not appear, see README for manual plugin steps."
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
" && success "shell.json patched" || warn "Could not patch shell.json - add manually (see README)"
else
    warn "shell.json not found - nightMode will appear after first launch"
fi

echo -e "\n${GREEN}${BOLD}  Done! Restart Caelestia to activate Night Mode.${RESET}\n"
