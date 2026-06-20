<div align="center">

# ✦ Lucidity

**Per-App Window Transparency for macOS**

A command-line transparency manager for the [AEON-mod](https://github.com/AEON-mod) ecosystem.
Powered by **yabai** and **skhd** — the standard toolchain for macOS tiling and hotkeys.

![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?style=flat-square&logo=gnubash&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-macOS%2012+-000000?style=flat-square&logo=apple&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-A6E3A1?style=flat-square)

</div>

---

## Overview

macOS doesn't expose per-window transparency through any public API. However, **yabai** — the most capable tiling window manager for macOS — provides `--opacity` control over individual windows.

Lucidity wraps yabai's opacity commands into a clean CLI with persistent config, hotkey integration via skhd, and a background sync daemon to keep your settings enforced.

---

## ✨ Features

| Feature | Description |
| :--- | :--- |
| **Per-App Opacity** | Unique opacity per application, saved to a plain-text config |
| **Hotkey Control** | Adjust, reset, toggle, and pin via keyboard shortcuts (skhd) |
| **Sync Daemon** | Background process that re-applies saved opacities every 2s |
| **Transparency Toggle** | Pause/resume opacity for any app without losing your config |
| **Always-On-Top (Sticky)** | Pin windows using yabai's sticky + topmost flags |
| **Quick Presets** | Jump to 90%, 80%, or 70% with a single hotkey |
| **macOS Notifications** | Visual feedback via native notification center |
| **Plain-Text Config** | Human-readable `opacity.conf` — easy to edit and version control |

---

## ⌨️ Hotkeys

> Defined in `skhdrc.example`. Append to your existing `~/.config/skhd/skhdrc`.

| Hotkey | Action |
| :--- | :--- |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>=</kbd> | Increase opacity (+5%) |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>-</kbd> | Decrease opacity (-5%) |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>/</kbd> | Reset to 100% |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>Space</kbd> | Toggle transparency ON/OFF |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>.</kbd> | Toggle Always-On-Top (pin) |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>1</kbd> | Quick-set 90% |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>2</kbd> | Quick-set 80% |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>3</kbd> | Quick-set 70% |

---

## 🚀 Setup

### Prerequisites

| Dependency | Install |
| :--- | :--- |
| **yabai** | `brew install koekeishiya/formulae/yabai` |
| **skhd** | `brew install koekeishiya/formulae/skhd` |
| **Python 3** | Pre-installed on macOS (used for JSON parsing) |

> **Important:** yabai requires [System Integrity Protection to be partially disabled](https://github.com/koekeishiya/yabai/wiki/Disabling-System-Integrity-Protection) for window opacity control. Without this, `--opacity` commands will silently fail.

### Installation

```bash
# 1. Create the config directory
mkdir -p ~/.config/lucidity

# 2. Copy the script and make it executable
cp lucidity.sh ~/.config/lucidity/
chmod +x ~/.config/lucidity/lucidity.sh

# 3. Append hotkey bindings to your skhd config
cat skhdrc.example >> ~/.config/skhd/skhdrc

# 4. Restart skhd to pick up the new bindings
skhd --restart-service
```

### Start the Sync Daemon

```bash
# Run in background (add to your login items or .zshrc)
~/.config/lucidity/lucidity.sh sync &
```

To auto-start on login, add to `~/.zshrc`:

```bash
# Auto-start Lucidity sync daemon
pgrep -f "lucidity.sh sync" > /dev/null || ~/.config/lucidity/lucidity.sh sync &
```

---

## 📖 CLI Reference

```
lucidity.sh <command> [args]
```

| Command | Description |
| :--- | :--- |
| `up` | Increase opacity of focused app (+5%) |
| `down` | Decrease opacity of focused app (-5%) |
| `set <val>` | Set opacity directly (0.15–1.0) |
| `reset` | Reset focused app to 100% |
| `toggle` | Toggle transparency ON/OFF for focused app |
| `pin` | Toggle Always-On-Top for focused window |
| `sync` | Start background sync daemon (run once) |
| `list` | Show all configured apps and their opacity |
| `help` | Show usage information |

### Examples

```bash
# Set iTerm2 to 80% opacity (focus iTerm2 first)
lucidity.sh set 0.80

# List all configured apps
lucidity.sh list
# ─── Lucidity Opacity Config ───
#   iTerm2                         80%
#   Visual Studio Code             90%
#   Discord                        85% (paused)
```

---

## 📂 File Structure

```
Window-transparency/
└── macOS/
    ├── lucidity.sh          # Main script
    ├── skhdrc.example       # Hotkey bindings template
    └── README.md            # This file

~/.config/lucidity/          # Runtime directory (auto-created)
    ├── opacity.conf         # Saved per-app opacities
    └── .state               # Pause/toggle state
```

### Config Format

`~/.config/lucidity/opacity.conf` is a plain key=value file:

```
iTerm2=0.80
Visual Studio Code=0.90
Discord=0.85
```

---

## ⚠️ Limitations

- **Requires yabai with SIP partially disabled.** Without scripting additions, yabai cannot control window opacity. This is a macOS security limitation, not a Lucidity issue.
- **No GUI.** macOS doesn't allow third-party overlay UIs as easily as Windows. The CLI + notification approach is the pragmatic choice.
- **Python 3 required** for JSON parsing of yabai query output. Pre-installed on all modern macOS versions.

---

## 📜 License

Open-source, part of the **AEON-mod** collection. Use, modify, and share freely.
