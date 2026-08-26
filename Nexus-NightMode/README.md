<div align="center">

# 🌙 Nexus Night Mode

**Blue-light filter toggle & intensity slider for [Caelestia](https://github.com/caelestia-shell/caelestia) shell**

*Live temperature control · No flicker · Persisted across restarts*

</div>

---

## ✦ What it adds

| Location | What you get |
|---|---|
| **Quick Toggles** | 🌙 Night mode button — one tap to enable / disable |
| **Nexus → Utilities** | Color temperature slider (1000 K – 6500 K), live preview |

Temperature changes apply **instantly** while dragging — no restart, no flash — via Hyprland's native hyprsunset IPC.

---

## ✦ Install hyprsunset

> Skip this if `hyprsunset` is already installed.

```bash
# Arch Linux
paru -S hyprsunset        # or: yay -S hyprsunset

# NixOS  (add to flake inputs)
inputs.hyprsunset.url = "github:hyprwm/hyprsunset";

# Build from source
git clone https://github.com/hyprwm/hyprsunset && cd hyprsunset
cmake -B build && sudo cmake --install build
```

---

## ✦ Quick install

> 💡 Don't want to do it manually? The script handles everything.

```bash
git clone https://github.com/AEON-mod/Scripts.git
cd Scripts/Nexus-NightMode/
bash install.sh
```

Restart Caelestia to apply changes:
```bash
pkill quickshell && quickshell & disown
```

---

## ✦ Manual install

<details>
<summary>Expand steps</summary>

### 1 · Copy QML files

```bash
BASE=/etc/xdg/quickshell/caelestia

sudo cp files/HyprSunset.qml       $BASE/services/HyprSunset.qml
sudo cp files/ServiceLoader.qml    $BASE/modules/ServiceLoader.qml
sudo cp files/Toggles.qml          $BASE/modules/utilities/cards/Toggles.qml
sudo cp files/UtilitiesPanel.qml   $BASE/modules/nexus/pages/panels/UtilitiesPanel.qml
```

### 2 · Rebuild the Caelestia plugin

> Needed so the C++ config registers the `nightMode` toggle slot.

```bash
cd ~/caelestia
sudo cp ~/Scripts/Nexus-NightMode/files/utilitiesconfig.hpp \
    plugin/src/Caelestia/Config/utilitiesconfig.hpp

direnv block .
rm -rf build
CXX=$(command -v g++ || command -v clang++)
cmake -S . -B build -G Ninja \
    -DCMAKE_CXX_COMPILER=$CXX \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DVERSION=0.0.1 -DENABLE_MODULES=plugin
cmake --build build -j$(nproc)
sudo cmake --install build
direnv allow .
```

### 3 · Register in shell.json

Add `nightMode` to your persisted quick-toggles list:

```bash
python3 - << 'EOF'
import json, os
p = f"{os.environ['HOME']}/.config/caelestia/shell.json"
d = json.load(open(p))
qt = d.setdefault('utilities', {}).setdefault('quickToggles', [])
if not any(e.get('id') == 'nightMode' for e in qt):
    qt.append({"id": "nightMode", "enabled": True})
    json.dump(d, open(p, 'w'), indent=2)
    print("Patched")
else:
    print("Already present")
EOF
```

### 4 · Restart Caelestia

</details>

---

## ✦ How it works

```
Toggle ON  →  hyprsunset -t <K>              (daemon starts, holds gamma)
Slide      →  hyprctl hyprsunset temperature K  (live IPC, no restart, no flicker)
Toggle OFF →  daemon killed → gamma auto-resets to normal
```

---

<div align="center">

*Made especially for [Caelestia](https://github.com/caelestia-shell/caelestia) · Hyprland · Quickshell*

</div>
