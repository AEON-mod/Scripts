<div align="center">

# ✦ Lucidity

**Per-App Window Transparency Manager**

Set, persist, and enforce per-application window opacity — designed for desktop ricers, tiling window manager users, and the [AEON-mod](https://github.com/AEON-mod) ecosystem.

![Windows](https://img.shields.io/badge/Windows-0078D4?style=flat-square&logo=windows&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-000000?style=flat-square&logo=apple&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-Native-FCC624?style=flat-square&logo=linux&logoColor=black)

</div>

---

## Why Lucidity?

Most tiling window managers aggressively redraw windows on every layout change — stripping transparency, topmost flags, and other custom styles in the process. Lucidity runs a lightweight background engine that **monitors and re-applies** your saved per-app opacity, so your aesthetic stays locked in.

---

## 📂 Platforms

| Platform | Approach | Folder |
| :--- | :--- | :--- |
| **Windows** | AutoHotkey v2 script with GUI, hotkeys, and a sync engine | [`Windows/`](./Windows/) |
| **macOS** | Bash CLI powered by **yabai** + **skhd** with a sync daemon | [`macOS/`](./macOS/) |
| **Linux** | ✅ Built-in — no script needed (see below) | — |

> Each folder contains its own **README** with full setup instructions, hotkey tables, and technical details.

---

## ⌨️ Hotkeys at a Glance

| Action | Windows | macOS |
| :--- | :--- | :--- |
| Open GUI / Set opacity | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>LClick</kbd> | `lucidity.sh set 0.80` |
| Increase opacity | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Num+</kbd> | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>=</kbd> |
| Decrease opacity | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Num-</kbd> | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>-</kbd> |
| Reset to 100% | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Num*</kbd> | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>/</kbd> |
| Toggle transparency | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>RClick</kbd> | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Space</kbd> |
| Pin (Always-On-Top) | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Space</kbd> | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>.</kbd> |

---

## 🐧 Linux — Native Support

Linux compositors handle per-window transparency out of the box. No external script is required:

```bash
# Hyprland
windowrulev2 = opacity 0.85, class:^(kitty)$

# Sway (swayfx)
for_window [app_id="kitty"] opacity 0.85

# i3 + picom
# In picom.conf:
opacity-rule = ["85:class_g = 'kitty'"];
```

**KDE Plasma** and **GNOME** also offer per-app opacity through System Settings → Window Rules and shell extensions, respectively. Unlike Windows TWMs, Linux compositors **don't strip transparency on layout changes**, so a sync engine isn't necessary.

---

## 📜 License

Open-source, part of the **AEON-mod** collection. Use, modify, and share freely.
