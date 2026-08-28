<div align="center">

# 🛸 AeonGlide for Windows

**AutoHotkey v2 — System-level mouse gesture engine**

[![AHK v2](https://img.shields.io/badge/AutoHotkey-v2.0+-334455?style=for-the-badge&logo=autohotkey&logoColor=white)](https://www.autohotkey.com/)
[![Admin](https://img.shields.io/badge/Privileges-Administrator-red?style=for-the-badge)]()

</div>

---

## 📦 Prerequisites

| Requirement | Version | Link |
|:---|:---|:---|
| AutoHotkey | v2.0+ | [autohotkey.com](https://www.autohotkey.com/) |
| Windows | 10 / 11 | — |

---

## 🚀 Quick Start

```
1.  Install AutoHotkey v2  →  https://www.autohotkey.com
2.  Double-click  AeonGlide.ahk
3.  Done. Look for the 🟢 tray icon.
```

The script auto-requests Administrator privileges on launch.

---

## ✨ Gesture Reference

| Gesture | Mouse Input | Action |
|:---|:---|:---|
| 📋 **Copy** | Double Right-Click | `Ctrl+C` |
| ✅ **Select All** | Triple Right-Click | `Ctrl+A` |
| 📥 **Paste** | Triple Left-Click | `Ctrl+V` |
| 🧭 **Back** | Right-Click + Swipe ← | `Alt+Left` |
| 🧭 **Forward** | Right-Click + Swipe → | `Alt+Right` |
| 🗂️ **Clipboard History** | Hold Left + Tap Right | `Win+V` |
| 📸 **Snipping Tool** | Hold Left + Hold Right | `Win+Shift+S` |
| 🖥️ **Task View** | Hover Top Edge (1s) | `Win+Tab` |

---

## 🎮 Game-Safe Mode

AeonGlide polls the foreground window every 2 seconds. If a known game is detected, all gesture hooks **suspend instantly** — zero interference with anti-cheat.

### Adding Your Games

1. Open **Task Manager** → **Details** tab
2. Find your game's process name (e.g. `Overwatch.exe`)
3. Add it to the `TargetGames` array in `AeonGlide.ahk`:

```autohotkey
global TargetGames := [
    "ahk_exe Valorant-Win64-Shipping.exe",
    "ahk_exe cs2.exe",
    "ahk_exe Overwatch.exe",              ; ← add here
]
```

### Visual Feedback

| State | Tray Icon | Tooltip |
|:---|:---|:---|
| Active | 🟢 Green checkmark | *AeonGlide v5.0.0 — Active* |
| Paused (game) | 🔴 Red X | *AeonGlide v5.0.0 — Paused* |
| Paused (manual) | 🔴 Red X | *AeonGlide v5.0.0 — Paused* |

---

## 🛡️ Controls

| Action | Shortcut |
|:---|:---|
| **Pause / Resume** | `Scroll Lock` |
| **Kill Switch** | `Shift + Escape` |
| **Tray Menu** | Right-click tray icon |

---

## ⚙️ Configuration

All tuneable values live in the `CFG` object at the top of the script:

```autohotkey
global CFG := {
    clickWindow     : 350,     ; Multi-click timing window (ms)
    singleClickDelay: 200,     ; Delay before single right-click (ms)
    swipeThreshold  : 50,      ; Min px for swipe detection
    holdThreshold   : 300,     ; Tap vs hold boundary (ms)
    edgeHoverDelay  : 1000,    ; Top-edge hover → Task View (ms)
    edgeHoverCooldown: 1500,   ; Cooldown after Task View (ms)
    gameCheckInterval: 2000,   ; Game detection polling (ms)
    edgeCheckInterval: 100,    ; Top-edge hover polling (ms)
}
```

---

## 🛠️ Run at Startup

### Easy Method

Drop `AeonGlide.ahk` (or a shortcut to it) into the Windows Startup folder:

```
Win+R  →  shell:startup  →  Enter
```

> ⚠️ This method triggers a UAC prompt on every login because the script requests admin.

### Pro Method (Silent Admin)

Use **Task Scheduler** to run with elevated privileges — no UAC popup.

1. Open **Task Scheduler** → **Create Task**
2. **General** tab:
   - Name: `AeonGlide`
   - ☑ *Run with highest privileges*
3. **Triggers** tab:
   - New → *At log on* → your user
4. **Actions** tab:
   - Program: `C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe`
   - Arguments: `"C:\path\to\AeonGlide.ahk"`
5. **Conditions** tab:
   - ☐ *Start only if on AC power*  (uncheck)

---

## 🐛 Troubleshooting

| Problem | Fix |
|:---|:---|
| Script doesn't start | Install AutoHotkey **v2**, not v1. Check the `.ahk` file association. |
| Right-click feels delayed | Lower `singleClickDelay` in `CFG` (try `150`). Trade-off: faster single-click but tighter double-click window. |
| Gestures don't work in certain apps | Some apps (e.g. elevated admin windows) need AeonGlide to also run as admin — which it does by default. |
| Tray icon missing | Right-click the taskbar → *Taskbar settings* → *System tray* → show hidden icons. |

---

<div align="center">

*Part of the [AEON-mod](../) ecosystem* · [← Back to Overview](../README.md)

</div>
