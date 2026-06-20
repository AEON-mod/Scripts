<div align="center">

# 🛸 AeonGlide

### *The Workflow Exploit.*

**Your mouse is underclocked. AeonGlide overclocks it.**

[![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)](./windows)
[![macOS](https://img.shields.io/badge/macOS-000000?style=for-the-badge&logo=apple&logoColor=white)](./macos)
[![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)](./linux)

<br>

*System-level input injection that maps high-speed macros to intuitive mouse gestures.*
*No UI. No bloat. No footprint. Just speed.*

</div>

---

## ✨ The Gesture Library

Every gesture is consistent across all three platforms.

| Gesture | Input | Windows | macOS | Linux |
|:---|:---|:---|:---|:---|
| 📋 **Copy** | Double Right-Click | `Ctrl+C` | `⌘C` | `Ctrl+C` |
| ✅ **Select All** | Triple Right-Click | `Ctrl+A` | `⌘A` | `Ctrl+A` |
| 📥 **Paste** | Triple Left-Click | `Ctrl+V` | `⌘V` | `Ctrl+V` |
| 🧭 **Back** | Right-Click + Swipe Left | `Alt+←` | `⌘[` | `Alt+←` |
| 🧭 **Forward** | Right-Click + Swipe Right | `Alt+→` | `⌘]` | `Alt+→` |
| 🗂️ **Clipboard** | Hold Left + Tap Right | `Win+V` | `⌘⇧V` | `Super+V` / Klipper |
| 📸 **Screenshot** | Hold Left + Hold Right | Snipping Tool | `⌘⇧4` | Flameshot / GNOME |
| 🖥️ **Overview** | Hover Top Edge (1s) | `Win+Tab` | Mission Control | Activities / Desktop Grid |

---

## 🎮 Intelligence: Game-Safe Mode

AeonGlide watches for game processes and **auto-suspends** all gesture hooks when one is in the foreground. No interference with anti-cheat — guaranteed.

| | Windows | macOS | Linux |
|:---|:---|:---|:---|
| **Detection** | Window title match | Bundle ID / App name | Process name scan |
| **Active icon** | 🟢 Green tray | 🟢 Menubar dot | `● Active` in terminal |
| **Paused icon** | 🔴 Red tray | 🔴 Menubar dot | `● Paused` in terminal |

---

## 🛡️ Controls

| Action | Windows | macOS | Linux |
|:---|:---|:---|:---|
| **Pause / Resume** | `Scroll Lock` | `⌃⌘P` | `kill -USR1 <pid>` |
| **Kill Switch** | `Shift + Escape` | `⌃⌘Escape` | `Ctrl+C` / `kill <pid>` |

---

## 📂 Platform Setup

Each platform has its own folder with a dedicated README:

| Platform | Directory | Runtime |
|:---|:---|:---|
| [**Windows**](./windows) | `windows/` | [AutoHotkey v2](https://www.autohotkey.com/) |
| [**macOS**](./macos) | `macos/` | [Hammerspoon](https://www.hammerspoon.org/) |
| [**Linux**](./linux) | `linux/` | Python 3.10+ / xdotool |

---

## ⚙️ Configuration

All platforms share the same tuneable parameters:

| Parameter | Default | Description |
|:---|:---|:---|
| `clickWindow` | 350 ms | Max time between clicks for multi-click detection |
| `singleClickDelay` | 200 ms | Delay before a lone right-click fires the context menu |
| `swipeThreshold` | 50 px | Minimum horizontal drag to register as a swipe |
| `holdThreshold` | 300 ms | Click shorter than this = tap; longer = hold |
| `edgeHoverDelay` | 1000 ms | Time hovering top edge before overview triggers |
| `gameCheckInterval` | 2000 ms | Polling interval for game process detection |

Edit the `config` / `CFG` block at the top of each script to tune these values.

---

<div align="center">

### 📡 Part of the **AEON-mod** ecosystem

*Designed for coders, creators, and power users.*
*Your mouse was always capable of this. Now it knows.*

**Run the script. Fly.** 🖱️✨

</div>
