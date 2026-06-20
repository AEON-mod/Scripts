<h1 align="center">🐧 TouchpadSwitch — Linux</h1>

<p align="center">
  <img src="https://img.shields.io/badge/X11-Supported-green?style=flat-square" alt="X11">
  <img src="https://img.shields.io/badge/Wayland-Supported-green?style=flat-square" alt="Wayland">
  <img src="https://img.shields.io/badge/Shortcut-Super%2BCtrl%2BL-blueviolet?style=flat-square" alt="Shortcut">
</p>

> Works on **Ubuntu, Fedora, Arch, Debian, Mint, Pop!\_OS, Manjaro, openSUSE** — any distro.

---

## 📋 Prerequisites

Your DE's tool should already be installed. Verify with the table below:

| Desktop | Tool Used | Check |
|---|---|---|
| GNOME / Budgie / Cinnamon | `gsettings` | Pre-installed |
| KDE Plasma | `qdbus6` or `qdbus` | Pre-installed with KDE |
| Sway | `swaymsg` | Pre-installed with Sway |
| Hyprland | `hyprctl` | Pre-installed with Hyprland |
| XFCE / MATE / Other (X11) | `xinput` | `sudo apt install xinput` |

Optional: `notify-send` for desktop notifications.

---

## 🚀 Install

```bash
git clone https://github.com/AEON-mod/TouchpadSwitch.git
cd TouchpadSwitch/linux
chmod +x install.sh touchpad-toggle.sh
./install.sh
```

**The installer will:**
1. Copy `touchpad-toggle` → `~/.local/bin/`
2. Auto-detect your DE
3. Register `Super+Ctrl+L` shortcut automatically

> If `~/.local/bin` isn't in your PATH, add to `~/.bashrc`:
> ```bash
> export PATH="$HOME/.local/bin:$PATH"
> ```

---

## 🎯 Usage

```bash
touchpad-toggle          # Toggle on/off
touchpad-toggle status   # Check state
touchpad-toggle on       # Force enable
touchpad-toggle off      # Force disable
```

---

## ⚙️ How It Works

The script auto-detects your display server and DE, then picks the best backend:

```
Wayland + GNOME  →  gsettings
Wayland + KDE    →  qdbus
Wayland + Sway   →  swaymsg
Wayland + Hypr   →  hyprctl
X11 + Any DE     →  xinput
```

State is tracked in `$XDG_RUNTIME_DIR/.touchpad-toggle-state`.

---

## 🔧 Shortcut Setup (if not auto-configured)

<details>
<summary><b>GNOME</b> — auto-configured by installer ✅</summary>

Manually: Settings → Keyboard → Custom Shortcuts → Add:
- **Name:** Touchpad Toggle
- **Command:** `touchpad-toggle`
- **Shortcut:** `Super+Ctrl+L`
</details>

<details>
<summary><b>KDE Plasma</b></summary>

System Settings → Shortcuts → Custom Shortcuts → Add:
- **Trigger:** `Super+Ctrl+L`
- **Action:** `~/.local/bin/touchpad-toggle`
</details>

<details>
<summary><b>Sway</b> — auto-configured by installer ✅</summary>

Or add manually to `~/.config/sway/config`:
```
bindsym Mod4+Control+l exec touchpad-toggle
```
Then: `swaymsg reload`
</details>

<details>
<summary><b>Hyprland</b> — auto-configured by installer ✅</summary>

Or add manually to `~/.config/hypr/hyprland.conf`:
```
bind = SUPER CTRL, L, exec, touchpad-toggle
```
</details>

<details>
<summary><b>Other / Generic</b></summary>

**X11** — add to `~/.xbindkeysrc`:
```
"touchpad-toggle"
  Control + Mod4 + l
```

**Wayland** — use `swhkd`, add to `~/.config/swhkd/swhkdrc`:
```
super + control + l
    touchpad-toggle
```
</details>

---

## 🗑️ Uninstall

```bash
rm ~/.local/bin/touchpad-toggle
```

Remove the shortcut from your DE settings.

---

## 🛠️ Troubleshooting

<details>
<summary><b>"No supported backend found"</b></summary>

```bash
# Ubuntu/Debian
sudo apt install xinput libnotify-bin

# Arch
sudo pacman -S xorg-xinput libnotify

# Fedora
sudo dnf install xinput libnotify
```
</details>

<details>
<summary><b>Touchpad not detected</b></summary>

```bash
# Check kernel devices
grep -i touchpad /proc/bus/input/devices

# X11
xinput list | grep -i touchpad

# Sway
swaymsg -t get_inputs | grep touchpad
```
</details>

---

<p align="center"><a href="../README.md">← Back to main README</a></p>
