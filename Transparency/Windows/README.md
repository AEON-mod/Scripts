<div align="center">

# ✦ Lucidity

**Per-App Window Transparency for Windows**

A precision transparency engine built for the [AEON-mod](https://github.com/AEON-mod) ecosystem.
Designed to coexist with tiling window managers like **GlazeWM** and **Komorebi** without style drift.

![AutoHotkey](https://img.shields.io/badge/AutoHotkey-v2.0-334455?style=flat-square&logo=autohotkey&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Windows%2010%2F11-0078D4?style=flat-square&logo=windows&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-A6E3A1?style=flat-square)

</div>

---

## The Problem

Tiling window managers redraw and reposition windows constantly. Every layout change can strip the `WS_EX_LAYERED` attribute, resetting your carefully tuned transparency back to fully opaque. Desktop "ricing" shouldn't require babysitting.

## The Solution

Lucidity runs a background **Sync Engine** that monitors every managed window and silently re-applies your per-app opacity settings whenever a TWM or the system resets them. Your config stays static. Your desktop stays crisp.

---

## ✨ Features

| Feature | Description |
| :--- | :--- |
| **Per-App Opacity** | Unique transparency levels per process — 85% for your terminal, 100% for your browser |
| **TWM Sync Engine** | Re-applies styles every 800ms to combat GlazeWM / Komorebi style drift |
| **Always-On-Top Pinning** | Pin any window above all others — enforced even when your TWM disagrees |
| **Transparency Toggle** | Instantly pause/resume transparency per app without losing your config |
| **Catppuccin Mocha GUI** | A dark, themed slider UI with live percentage preview |
| **Buffered I/O** | Disk writes are batched every 20s — your SSD stays healthy |
| **Ghost Window Filtering** | Ignores taskbars, desktop shells, TWM bars, and invisible overlays |
| **Exit-Safe Persistence** | Unsaved changes are flushed to disk on script exit |
| **System Tray Integration** | Reload, open config, or exit cleanly from the tray icon |

---

## ⌨️ Hotkeys

| Hotkey | Action |
| :--- | :--- |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>LClick</kbd> | Open the Lucidity GUI for the focused app |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>Numpad +</kbd> | Increase opacity (+15 / ~6%) |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>Numpad -</kbd> | Decrease opacity (-15 / ~6%) |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>Numpad *</kbd> | Reset to 100% opaque (removes from config) |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>Space</kbd> | Toggle Always-On-Top (pin/unpin) |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>RClick</kbd> | Toggle transparency ON/OFF for current app |

---

## 🚀 Setup

### Prerequisites

- [AutoHotkey v2.0+](https://www.autohotkey.com/v2/)

### Installation

1. Download **`Lucidity.ahk`** into your AEON-mod directory (or anywhere you like).
2. Double-click to run. A tray icon labeled **"Lucidity"** will appear.
3. <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>LClick</kbd> on any window to set its opacity.

### Autostart

Drop `Lucidity.ahk` (or a shortcut to it) into your **Startup folder**:

```
Win + R  →  shell:startup  →  paste shortcut
```

---

## 🛠 Technical Details

### Sync Engine

The engine polls every **800ms** (configurable via `SYNC_INTERVAL`). For each tracked process it:

1. Enumerates all windows (`WinGetList`)
2. Filters out ghost/system windows via class-name matching
3. Reads the current transparency attribute
4. Re-applies the saved value only if it has drifted

> **Note:** `WinGetTransparent` returns `""` for windows that have never been layered. Lucidity handles this correctly by treating `""` as `255` (fully opaque).

### Filtered Window Classes

The following classes are excluded from the engine to prevent UI breakage:

| Class | Source |
| :--- | :--- |
| `Shell_TrayWnd` | Windows Taskbar |
| `WorkerW` / `Progman` | Desktop & wallpaper |
| `Komobar` / `GlazeWM` | TWM UI elements |
| `TaskSwitcherWnd` | Alt-Tab overlay |
| `Windows.UI.Core` | UWP system frames |
| `NotifyIconOverflowWindow` | Tray overflow |

### Config File

Settings are stored in `TransparencySettings.ini` in the script's directory:

```ini
[AppCapacities]
windowsterminal.exe=200
code.exe=230
discord.exe=240

[PinnedApps]
windowsterminal.exe=1
```

---

## 📂 File Structure

```
Window-transparency/
└── Windows/
    ├── Lucidity.ahk                # The script
    ├── TransparencySettings.ini    # Auto-generated config (created on first use)
    └── README.md                   # This file
```

---

## 📜 License

Open-source, part of the **AEON-mod** collection. Use, modify, and share freely.
