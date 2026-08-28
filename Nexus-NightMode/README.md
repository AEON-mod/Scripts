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

# Build from source
git clone https://github.com/hyprwm/hyprsunset && cd hyprsunset
cmake -B build && sudo cmake --install build
```

---

## ✦ Quick install

> 💡 **Recommended:** The script handles all the patching dynamically, regardless of what version of Caelestia you are on!

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

### 1 · Add the backend service

```bash
BASE=/etc/xdg/quickshell/caelestia
sudo cp files/HyprSunset.qml $BASE/services/HyprSunset.qml
```
*Note: Because Caelestia has different UI versions across forks (like midnight-shell), manually copying the UI files is discouraged. Please use the `install.sh` script which dynamically injects the UI buttons into your specific version's QML.*

### 2 · Register in shell.json

Add `nightMode` to your persisted quick-toggles list:

```bash
python3 - << 'PYEOF'
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
PYEOF
```

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

*For [Caelestia](https://github.com/caelestia-shell/caelestia) · Hyprland · Quickshell*

</div>
