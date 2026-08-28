<p align="center">
  <img src="https://img.shields.io/badge/Platform-Linux%20%7C%20Windows%20%7C%20macOS-blue?style=for-the-badge" alt="Platform">
  <img src="https://img.shields.io/badge/Shortcut-Super%2BCtrl%2BL-blueviolet?style=for-the-badge" alt="Shortcut">
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License">
</p>

<h1 align="center">🖱️ TouchpadSwitch</h1>

<p align="center">
  <b>Toggle your laptop touchpad ON/OFF with a single keyboard shortcut.</b><br>
  <code>Super + Ctrl + L</code>
</p>

---

## ✨ Features

- ⌨️ One shortcut — `Win/Super + Ctrl + L`
- 🐧 **Linux** — GNOME, KDE, Sway, Hyprland, XFCE (X11 + Wayland)
- 🪟 **Windows** — AutoHotkey v2 + PowerShell
- 🍎 **macOS** — Shell script + Karabiner-Elements
- 🔔 Desktop notifications on toggle

---

## 📂 Structure

```
TouchpadSwitch/
├── linux/    ← 🐧 Bash script + auto-installer
├── windows/  ← 🪟 AutoHotkey v2 script + installer
├── macos/    ← 🍎 Shell script + Karabiner config
└── README.md
```

**Each folder has its own README with full setup instructions.**

---

## 🚀 Quick Start

### 🐧 Linux
```bash
cd linux && chmod +x install.sh touchpad-toggle.sh && ./install.sh
```
→ [Full instructions](linux/README.md)

### 🪟 Windows
```
Right-click install.bat → "Run as administrator"
```
→ [Full instructions](windows/README.md)

### 🍎 macOS
```bash
cp macos/touchpad-toggle.sh ~/.local/bin/touchpad-toggle && chmod +x ~/.local/bin/touchpad-toggle
```
→ [Full instructions](macos/README.md)

---

## ⚙️ At a Glance

| | Linux | Windows | macOS |
|---|:---:|:---:|:---:|
| **Shortcut** | `Super+Ctrl+L` | `Win+Ctrl+L` | `⌘+⌃+L` |
| **Admin** | No | Yes | No |
| **External Mouse** | Not needed | Not needed | Required |

---

## 📄 License

[MIT](LICENSE)

<p align="center">Made with ❤️ by <a href="https://github.com/AEON-mod">AEON-mod</a></p>
