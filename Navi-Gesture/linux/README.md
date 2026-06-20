<div align="center">

# 🛸 AeonGlide for Linux

**Python 3 — X11 mouse gesture engine with DE-aware dispatch**

[![Python](https://img.shields.io/badge/Python-3.10+-3776AB?style=for-the-badge&logo=python&logoColor=white)]()
[![X11](https://img.shields.io/badge/Display-X11%20%2F%20XWayland-orange?style=for-the-badge)]()

</div>

---

## 📦 Prerequisites

| Requirement | Install |
|:---|:---|
| Python | 3.10+ (usually pre-installed) |
| xdotool | `sudo apt install xdotool` / `sudo dnf install xdotool` / `sudo pacman -S xdotool` |
| pynput | `pip install pynput` |
| psutil | `pip install psutil` |

### Display Server Compatibility

| Display Server | Status |
|:---|:---|
| **X11 / Xorg** | ✅ Full support |
| **XWayland** (GNOME, KDE) | ⚠️ Works in most cases — xdotool uses XWayland bridge |
| **Pure Wayland** | ❌ Not supported — pynput cannot intercept mouse events |

> [!NOTE]
> Most GNOME and KDE sessions on Wayland still run XWayland, which allows xdotool and pynput to function. The script auto-detects your session type and warns if pure Wayland is detected.

---

## 🚀 Quick Start

```bash
# 1. Install system dependency
sudo apt install xdotool          # Debian / Ubuntu
sudo dnf install xdotool          # Fedora
sudo pacman -S xdotool            # Arch

# 2. Install Python dependencies
pip install -r requirements.txt

# 3. Run
python3 AeonGlide.py
```

You'll see:

```
============================================================
  🛸 AeonGlide v5.0.0 — Linux (GNOME)
  PID: 12345  |  Toggle: kill -USR1 12345
  Stop:  Ctrl+C  or  kill 12345
============================================================
  🛸 AeonGlide v5.0.0 — ● Active
```

---

## ✨ Gesture Reference

| Gesture | Mouse Input | Action |
|:---|:---|:---|
| 📋 **Copy** | Double Right-Click | `Ctrl+C` |
| ✅ **Select All** | Triple Right-Click | `Ctrl+A` |
| 📥 **Paste** | Triple Left-Click | `Ctrl+V` |
| 🧭 **Back** | Right-Click + Swipe ← | `Alt+Left` |
| 🧭 **Forward** | Right-Click + Swipe → | `Alt+Right` |
| 🗂️ **Clipboard** | Hold Left + Tap Right | `Super+V` (GNOME) / `Ctrl+Alt+V` (KDE) |
| 📸 **Screenshot** | Hold Left + Hold Right | Flameshot / GNOME Screenshot / scrot |
| 🖥️ **Overview** | Hover Top Edge (1s) | Activities (GNOME) / Desktop Grid (KDE) |

### DE-Aware Dispatch

AeonGlide auto-detects your desktop environment via `$XDG_CURRENT_DESKTOP` and picks the correct shortcuts:

| Feature | GNOME | KDE Plasma | XFCE | Cinnamon |
|:---|:---|:---|:---|:---|
| Clipboard History | `Super+V` | `Ctrl+Alt+V` | `Super+V` | `Super+V` |
| Screenshot | `Shift+Print` | `Shift+Print` | `Shift+Print` | `Shift+Print` |
| Overview | `Super` | `Ctrl+F10` | `Super+D` | `Super` |

> [!TIP]
> If [Flameshot](https://flameshot.org/) is installed, it takes priority over all DE-native screenshot tools. Install it for the best cross-DE screenshot experience:
> ```bash
> sudo apt install flameshot    # or your distro's equivalent
> ```

---

## 🎮 Game-Safe Mode

AeonGlide scans running processes every 2 seconds. If a known game process is found, all gesture hooks **suspend instantly**.

### Adding Your Games

Find the game's process name:

```bash
# While the game is running:
ps aux | grep -i "game"
# or
pgrep -la "game"
```

Add the process name (or a unique substring) to `TARGET_GAMES` in `AeonGlide.py`:

```python
TARGET_GAMES: list[str] = [
    "valiant-Win64",       # Valorant (Proton)
    "cs2_linux64",         # CS2 native
    "minecraft-launcher",  # Minecraft
    "Overwatch.exe",       # ← add here (Proton name)
]
```

The match is case-insensitive and uses substring matching — `"steam_app_"` catches all Steam/Proton games.

### Visual Feedback

```
🛸 AeonGlide v5.0.0 — ● Active          ← normal operation
🛸 AeonGlide v5.0.0 — ● Paused (game detected)   ← auto-suspended
🛸 AeonGlide v5.0.0 — ● Paused (manual)            ← manual toggle
```

---

## 🛡️ Controls

| Action | Method |
|:---|:---|
| **Pause / Resume** | `kill -USR1 <pid>` from another terminal |
| **Kill Switch** | `Ctrl+C` in the terminal, or `kill <pid>` |

Quick toggle alias for your `.bashrc` / `.zshrc`:

```bash
alias ag-toggle='kill -USR1 $(pgrep -f AeonGlide.py)'
alias ag-stop='kill $(pgrep -f AeonGlide.py)'
```

---

## ⚙️ Configuration

Edit the `Config` dataclass at the top of `AeonGlide.py`:

```python
@dataclass
class Config:
    click_window: float       = 0.35   # Multi-click timing window (seconds)
    single_click_delay: float = 0.22   # Delay before single right-click (seconds)
    swipe_threshold: int      = 50     # Min px for swipe detection
    hold_threshold: float     = 0.30   # Tap vs hold boundary (seconds)
    edge_hover_delay: float   = 1.0    # Top-edge hover → overview (seconds)
    edge_hover_cooldown: float= 1.5    # Cooldown after overview (seconds)
    game_check_interval: float= 2.0    # Game detection polling (seconds)
    edge_check_interval: float= 0.1    # Top-edge hover polling (seconds)
```

---

## 🛠️ Run at Login

### GNOME / Cinnamon / MATE

Create a `.desktop` autostart entry:

```bash
mkdir -p ~/.config/autostart

cat > ~/.config/autostart/AeonGlide.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=AeonGlide
Comment=Advanced Mouse Gestures
Exec=/usr/bin/python3 /path/to/AeonGlide.py
Terminal=false
X-GNOME-Autostart-enabled=true
EOF
```

### KDE Plasma

```
System Settings → Startup and Shutdown → Autostart → Add Script → select AeonGlide.py
```

### Systemd User Service

```bash
cat > ~/.config/systemd/user/AeonGlide.service << 'EOF'
[Unit]
Description=AeonGlide Mouse Gestures
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /path/to/AeonGlide.py
Restart=on-failure
RestartSec=5
Environment=DISPLAY=:0

[Install]
WantedBy=graphical-session.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now AeonGlide.service
```

---

## ⚠️ Known Limitations

| Limitation | Details |
|:---|:---|
| **Right-click pass-through** | On Linux (X11), pynput listens but doesn't suppress native mouse events. Single right-clicks work naturally; gesture right-clicks may briefly flash a context menu before the action fires. |
| **Wayland** | Pure Wayland sessions cannot intercept mouse events via pynput. Use X11 or XWayland. |
| **Root apps** | Gestures may not work in apps run as root (e.g. `sudo nautilus`). Run AeonGlide as root to match privilege levels. |
| **Gaming mice** | Some gaming mice with vendor drivers (Logitech, Razer) may intercept button events before they reach X11. Disable vendor software or remap buttons to standard mouse buttons. |

---

## 🐛 Troubleshooting

| Problem | Fix |
|:---|:---|
| `ModuleNotFoundError: pynput` | `pip install pynput` — use `pip3` if `pip` points to Python 2. |
| `xdotool: command not found` | Install xdotool via your package manager. |
| Script crashes on launch | Check `XDG_SESSION_TYPE`: if it's `wayland`, try `export GDK_BACKEND=x11` or switch to an X11 session. |
| Gestures fire but nothing happens | Verify `xdotool key ctrl+c` works in a terminal. Some Wayland compositors block xdotool. |
| Wrong DE detected | Set `XDG_CURRENT_DESKTOP` manually or edit the `DE` variable in the script. |

---

<div align="center">

*Part of the [AEON-mod](../) ecosystem* · [← Back to Overview](../README.md)

</div>
