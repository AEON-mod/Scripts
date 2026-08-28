<div align="center">

# 🛸 AeonGlide for macOS

**Hammerspoon — Lua-powered mouse gesture engine**

[![Hammerspoon](https://img.shields.io/badge/Hammerspoon-0.9.100+-000000?style=for-the-badge&logo=lua&logoColor=white)](https://www.hammerspoon.org/)
[![macOS](https://img.shields.io/badge/macOS-13%20Ventura+-000000?style=for-the-badge&logo=apple&logoColor=white)]()

</div>

---

## 📦 Prerequisites

| Requirement | Install |
|:---|:---|
| Hammerspoon | `brew install --cask hammerspoon` or [hammerspoon.org](https://www.hammerspoon.org/) |
| macOS | 13 Ventura or later (Intel & Apple Silicon) |
| Accessibility | System Settings → Privacy & Security → Accessibility → ☑ Hammerspoon |

> [!IMPORTANT]
> Hammerspoon **must** be granted Accessibility permissions to intercept mouse events. Without this, AeonGlide will load but gestures won't work.

---

## 🚀 Quick Start

```bash
# 1. Install Hammerspoon
brew install --cask hammerspoon

# 2. Copy the script
cp AeonGlide.lua ~/.hammerspoon/AeonGlide.lua

# 3. Load it from your init.lua
echo 'require("AeonGlide")' >> ~/.hammerspoon/init.lua

# 4. Reload Hammerspoon  (⌘⇧R  or menubar → Reload Config)
```

Look for the **🟢** dot in your menu bar — you're live.

---

## ✨ Gesture Reference

| Gesture | Mouse Input | Action |
|:---|:---|:---|
| 📋 **Copy** | Double Right-Click | `⌘C` |
| ✅ **Select All** | Triple Right-Click | `⌘A` |
| 📥 **Paste** | Triple Left-Click | `⌘V` |
| 🧭 **Back** | Right-Click + Swipe ← | `⌘[` |
| 🧭 **Forward** | Right-Click + Swipe → | `⌘]` |
| 🗂️ **Clipboard** | Hold Left + Tap Right | `⌘⇧V` |
| 📸 **Screenshot** | Hold Left + Hold Right | `⌘⇧4` (region select) |
| 🖥️ **Mission Control** | Hover Top Edge (1s) | `⌃↑` |

> **Clipboard History:** macOS doesn't have a built-in clipboard manager. `⌘⇧V` triggers "Paste and Match Style" in most apps. For a true clipboard history, pair AeonGlide with [Maccy](https://maccy.app/) (free) or [Paste](https://pasteapp.io/) and remap the shortcut in the `config` table.

---

## 🎮 Game-Safe Mode

AeonGlide checks the frontmost application every 2 seconds. If a known game is detected, all gesture hooks **suspend instantly**.

### Adding Your Games

Find the app's **bundle identifier**:

```bash
osascript -e 'id of app "Minecraft"'
# → com.mojang.minecraftlauncher
```

Then add it to the `targetGames` table in `AeonGlide.lua`:

```lua
local targetGames = {
    "com.riotgames.LeagueofLegends.GameClient",
    "com.valvesoftware.cs2",
    "com.mojang.minecraftlauncher",   -- ← existing
    "net.blizzard.overwatch",          -- ← add here
}
```

You can also use the app's display name (`"Overwatch"`) as a fallback.

### Visual Feedback

| State | Menubar |
|:---|:---|
| Active | 🟢 |
| Paused (game) | 🔴 |
| Paused (manual) | 🔴 |

Click the menubar icon for a dropdown with **Pause / Resume** and **Quit**.

---

## 🛡️ Controls

| Action | Shortcut |
|:---|:---|
| **Pause / Resume** | `⌃⌘P` |
| **Kill Switch** | `⌃⌘Escape` |
| **Menubar** | Click 🟢 / 🔴 icon |

---

## ⚙️ Configuration

Edit the `config` table at the top of `AeonGlide.lua`:

```lua
local config = {
    clickWindow       = 0.35,   -- Multi-click timing window (seconds)
    singleClickDelay  = 0.20,   -- Delay before single right-click (seconds)
    swipeThreshold    = 50,     -- Min px for swipe detection
    holdThreshold     = 0.30,   -- Tap vs hold boundary (seconds)
    edgeHoverDelay    = 1.0,    -- Top-edge hover → Mission Control (seconds)
    edgeHoverCooldown = 1.5,    -- Cooldown after Mission Control (seconds)
    gameCheckInterval = 2.0,    -- Game detection polling (seconds)
    edgeCheckInterval = 0.1,    -- Top-edge hover polling (seconds)
}
```

---

## 🛠️ Run at Login

Hammerspoon has a built-in "Launch at Login" option:

1. Click the **Hammerspoon** menu bar icon (🔨)
2. Select **Preferences...**
3. ☑ **Launch Hammerspoon at login**

Since `AeonGlide.lua` is loaded via `init.lua`, it starts automatically with Hammerspoon.

---

## 🐛 Troubleshooting

| Problem | Fix |
|:---|:---|
| Gestures don't work | Grant Accessibility permissions: *System Settings → Privacy & Security → Accessibility → ☑ Hammerspoon*. Restart Hammerspoon after granting. |
| Right-click feels slow | Lower `singleClickDelay` (try `0.15`). |
| Mission Control doesn't trigger | Check that `⌃↑` is mapped to Mission Control in *System Settings → Desktop & Dock → Mission Control → Keyboard Shortcuts*. |
| Hammerspoon console shows errors | Open the console (`⌘⌥C`) and check for Lua syntax errors. |
| `⌘⇧V` doesn't open clipboard | Install [Maccy](https://maccy.app/) and set its hotkey to `⌘⇧V`. |

---

## 📝 Integrating with Existing init.lua

If you already have a `~/.hammerspoon/init.lua`, just add one line:

```lua
-- Your existing config...
hs.window.animationDuration = 0

-- Load AeonGlide
require("AeonGlide")

-- Your other modules...
require("windowmanager")
```

AeonGlide is self-contained and won't interfere with other Hammerspoon modules.

---

<div align="center">

*Part of the [AEON-mod](../) ecosystem* · [← Back to Overview](../README.md)

</div>
