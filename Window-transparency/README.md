# Lucidity

**Lucidity** is a high-performance, per-app transparency and window management utility designed for modular Windows optimization. Built with **AutoHotkey v2**, it is engineered to function seamlessly alongside Tiling Window Managers (TWMs) like **GlazeWM** and **Komorebi**.

Part of the **AEON-mod** ecosystem, Lucidity ensures that your "ricing" configuration remains static and crisp, even when your window manager is moving or resizing windows.

---

## ✨ Features

- **Per-App Capacities:** Set unique transparency levels for different applications (e.g., 80% for Terminal, 100% for Browser).
- **TWM Sync Engine:** Actively monitors and re-applies styles to combat "style drift" caused by GlazeWM or Komorebi.
- **Persistent Storage:** Automatically saves your configurations to a local `.ini` file.
- **Always-On-Top (Pinning):** High-priority enforcement for pinned windows that tiling engines can't break.
- **Catppuccin Mocha UI:** A modern, sleek GUI designed to match high-end aesthetic desktop setups.
- **Buffered I/O:** Optimized to protect SSD lifespan by grouping disk writes.
- **Ghost Window Filtering:** Intelligently ignores system shells, taskbars, and invisible overlays.

---

## ⌨️ Hotkeys

| Hotkey | Action |
| :--- | :--- |
| `Ctrl + Shift + LClick` | Open Lucidity Management GUI |
| `Ctrl + Shift + Space` | Toggle Always-On-Top (Pin) |
| `Ctrl + Shift + Numpad +` | Increase Capacity (+15) |
| `Ctrl + Shift + Numpad -` | Decrease Capacity (-15) |
| `Ctrl + Shift + Numpad *` | Reset to 100% Opaque (Remove from config) |
| `Ctrl + Shift + RClick` | Toggle Transparency ON/OFF for current app |

---

## 🚀 Installation & Usage

### Prerequisites
- [AutoHotkey v2.0+](https://www.autohotkey.com/v2/)

### Setup
1. Download `Lucidity.ahk`.
2. Place it in your AEON-mod directory.
3. Run the script. A "ghost" icon will appear in your System Tray.
4. Use `Ctrl + Shift + LClick` on any window to start customizing its capacity.
5. For autostart drop the file in startup folder.

---

## 🛠 Technical Details

### The Sync Engine
Tiling Window Managers often redraw windows when layouts change, which can strip the `WS_EX_LAYERED` attribute. **Lucidity** runs a background sync engine every 400ms to verify that the window's actual transparency matches your saved preference in the `.ini` file.

### Filtered Classes
To prevent UI breakage, the following classes are ignored by the engine:
- `Shell_TrayWnd` (Taskbar)
- `WorkerW` / `Progman` (Desktop)
- `Komobar` / `GlazeWM` (TWM UI elements)

---

## 📜 License

This project is open-source and part of the **AEON-mod** collection. It's open source and I do not claim it as my own.
