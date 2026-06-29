<div align="center">

# 🎬 mpvpaper Live Wallpaper

**GPU-accelerated video wallpapers for Hyprland — built for [Caelestia](https://github.com/caelestia-dots/caelestia) dotfiles**

[![Hyprland](https://img.shields.io/badge/Hyprland-Wayland-blue?style=flat-square&logo=wayland)](https://hyprland.org)
[![mpvpaper](https://img.shields.io/badge/mpvpaper-1.8-orange?style=flat-square)](https://github.com/GhostNaN/mpvpaper)
[![GPU](https://img.shields.io/badge/GPU-NVDEC%20accelerated-76b900?style=flat-square&logo=nvidia)](https://developer.nvidia.com)
[![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?style=flat-square&logo=gnubash)](https://www.gnu.org/software/bash/)

Play any `.mp4 / .webm / .mkv` as your desktop wallpaper with hardware decoding,  
automatic color scheme extraction, and full Caelestia integration — at ~20% CPU.

</div>

---

## ✨ Features

- 🎮 **NVDEC hardware decoding** — GPU does the work, not your CPU
- 🔄 **Cycles wallpapers** — press the keybind to jump to the next video
- 🎨 **Caelestia color extraction** — updates your shell theme from a video frame
- 🔋 **Auto-sleep** — mpvpaper pauses when wallpaper is fully covered (saves power)
- 🔄 **Persist across reboots** — startup script auto-restores your last video
- 🛠 **Batch transcoder** — downscales 4K/1440p to your screen resolution in one command
- 🐧 **Wallpaper Engine compatible** — coexists cleanly with linux-wallpaperengine scenes

---

## 📋 Requirements

| Package | Purpose |
|---------|---------|
| `mpvpaper` | Video wallpaper engine |
| `ffmpeg` | Frame extraction + transcoding |
| `jq` | Editing `shell.json` for Caelestia |
| `caelestia` | Color scheme updates from video frame |
| `hyprctl` | Screen resolution detection |

```bash
# Arch / CachyOS / EndeavourOS
sudo pacman -S mpvpaper ffmpeg jq
# caelestia is installed as part of the Caelestia dotfiles setup
```

---

## 📁 File Structure

```
mpvpaper-live-wallpaper/
├── live-wallpaper.sh          ← Main script — launch / cycle wallpapers
├── wallpaper-hook.sh          ← Caelestia post-hook (runs after wallpaper change)
├── wallpaper-startup.sh       ← Restores wallpaper on Hyprland startup
├── transcode-wallpapers.sh    ← Batch downscale 4K→1080p with NVENC
├── game-mode.sh               ← (optional) Power profile switcher
├── cpu-power-limits.service   ← (optional) Systemd service for CPU TDP limits
└── README.md
```

**Install locations** (where files actually live on your system):
```
~/.config/hypr/scripts/live-wallpaper.sh
~/.config/hypr/scripts/wallpaper-hook.sh       ← symlinked from Caelestia
~/.config/hypr/scripts/wallpaper-startup.sh    ← symlinked from Caelestia
~/Pictures/Wallpapers/live-wallpaper/          ← drop your videos here
```

---

## 🚀 Installation

### 1 — Clone and copy scripts

```bash
git clone git@github.com:AEON-mod/Scripts.git ~/GitHub/personal/Scripts
cd ~/GitHub/personal/Scripts/mpvpaper-live-wallpaper

# Copy the main script
cp live-wallpaper.sh ~/.config/hypr/scripts/live-wallpaper.sh
chmod +x ~/.config/hypr/scripts/live-wallpaper.sh
```

> **Caelestia users:** `wallpaper-hook.sh` and `wallpaper-startup.sh` are managed by  
> Caelestia itself inside `~/.local/share/caelestia/hypr/scripts/`. Do **not** overwrite them —  
> they are already configured. Only copy `live-wallpaper.sh`.

### 2 — Create the wallpaper directory

```bash
mkdir -p ~/Pictures/Wallpapers/live-wallpaper
# Drop any .mp4 / .webm / .mkv files in here
```

### 3 — Add a Hyprland keybind

Add this to your `~/.config/hypr/hyprland.conf` (or user config):

```conf
bind = $mainMod, W, exec, bash ~/.config/hypr/scripts/live-wallpaper.sh
```

Press `Super + W` to launch / cycle to the next video wallpaper.

### 4 — (Recommended) Transcode high-res videos

If you have 4K or 1440p wallpapers, transcode them down to your screen resolution first.  
This alone drops CPU usage from ~90% to ~20%:

```bash
bash ~/GitHub/personal/Scripts/mpvpaper-live-wallpaper/transcode-wallpapers.sh
```

---

## 🎮 Usage

```bash
# Cycle to the next video in ~/Pictures/Wallpapers/live-wallpaper/
bash ~/.config/hypr/scripts/live-wallpaper.sh

# Play a specific video file
bash ~/.config/hypr/scripts/live-wallpaper.sh ~/Pictures/Wallpapers/live-wallpaper/city.mp4

# Stop the wallpaper
killall mpvpaper

# Batch transcode all oversized videos (run once after adding new wallpapers)
bash ~/GitHub/personal/Scripts/mpvpaper-live-wallpaper/transcode-wallpapers.sh
```

---

## 🔗 How It Works with Caelestia

Caelestia manages wallpapers through `caelestia wallpaper -f <image>`, which calls `wallpaper-hook.sh` via a post-hook.  
Video wallpapers need special handling to avoid a conflict loop:

```
Super+W pressed
    └─► live-wallpaper.sh
            ├─ Kills any existing mpvpaper / wallpaperengine
            ├─ Sets shell.json → wallpaperEnabled: false   (hides Caelestia's image layer)
            ├─ Launches mpvpaper with nvdec-copy
            ├─ Extracts a frame from the video with ffmpeg
            └─ Calls: LIVE_WALLPAPER_COLORS_ONLY=1 caelestia wallpaper -f <frame>
                    └─► wallpaper-hook.sh
                            └─ Sees env var → exits immediately (does NOT kill mpvpaper)
                                              (color scheme updates silently in background)
```

**Switching back to a static image wallpaper** via Caelestia's normal UI:
```
caelestia wallpaper -f image.jpg
    └─► wallpaper-hook.sh
            ├─ Kills mpvpaper
            ├─ Removes is_live_wallpaper_active flag
            └─ Sets shell.json → wallpaperEnabled: true   (re-enables Caelestia's image layer)
```

**On Hyprland startup**, `wallpaper-startup.sh` checks for the `is_live_wallpaper_active` flag and  
auto-resumes the last video — so your live wallpaper persists across reboots.

---

## ⚡ Performance Guide

### Why your CPU spikes — and how to fix it

#### ❌ Problem 1 — `vf=scale` destroys CPU

Using `vf=scale=WxH` forces software scaling on every decoded frame at full framerate:

```bash
# ❌ Wrong — CPU spikes to 90%+
mpvpaper -o "hwdec=nvdec vf=scale=1920:1080" '*' video.mp4

# ✅ Correct — compositor handles scaling natively at zero CPU cost
mpvpaper -s -o "loop=yes hwdec=nvdec-copy hwdec-codecs=all mute=yes panscan=1.0" '*' video.mp4
```

#### ❌ Problem 2 — `hwdec=nvdec` silently falls back to CPU

mpvpaper uses a **libmpv EGL surface**, not a native dmabuf surface. Pure `nvdec` requires  
zero-copy GPU→compositor handoff via dmabuf — which mpvpaper can't provide. It silently falls  
back to software decode with no warning.

```bash
# ❌ Silently uses CPU on mpvpaper
hwdec=nvdec

# ✅ GPU decodes, copies frame to RAM for EGL upload — correct for mpvpaper
hwdec=nvdec-copy hwdec-codecs=all
```

#### ❌ Problem 3 — Playing 4K video on a 1080p screen

The GPU decodes 4× more pixels than your screen needs, copies the giant frame to RAM, and  
the compositor scales it down — 4× wasted work at 60fps. Pre-transcode instead:

```bash
bash transcode-wallpapers.sh   # auto-detects your screen resolution
```

**Before vs After:**

| Metric | 4K60 naive | 1080p30 transcoded ✅ |
|--------|-----------|----------------------|
| CPU | ~90% | **~20%** |
| Temps | ~87°C | **~65°C** |
| Dropped frames | 200+/min | **0** |

#### ❌ Problem 4 — ffmpeg/ffprobe wrapped in Firejail

Some setups symlink `/usr/local/bin/ffmpeg` → `/usr/bin/firejail`, which blocks GPU access  
and causes permission errors. The transcode script auto-detects and bypasses this by calling  
`/usr/bin/ffmpeg` directly.

```bash
# Check if you're affected
ls -la $(which ffmpeg)
# If it points to /usr/bin/firejail — you are
```

---

## 📊 Benchmarks

> Tested on: **Intel i7-12650HX · RTX 4050 Laptop · 1920×1080 · Hyprland · CachyOS**

| Scenario | CPU % | Temp | Dropped Frames |
|----------|-------|------|----------------|
| 4K60 + `vf=scale` + `nvdec-copy` | ~94% | 87–89°C | 200+/min |
| 4K60, no `vf=scale` + `nvdec-copy` | ~45% | ~80°C | ~50/min |
| **1080p30 + `nvdec-copy`** ✅ | **~20%** | **~65°C** | **0** |

---

## ❓ FAQ

**Q: Does this work on AMD GPUs?**  
Replace `hwdec=nvdec-copy` with `hwdec=vaapi-copy`. In `transcode-wallpapers.sh`, change `h264_nvenc` → `h264_vaapi` and remove the CUDA hwaccel flags.

**Q: Does this work without a dedicated GPU?**  
Yes. Use `hwdec=auto` and remove NVENC flags in the transcode script. Software decode at 1080p30 is manageable on modern CPUs.

**Q: My video plays but Caelestia's color scheme doesn't update.**  
Make sure `ffmpeg` can access the video file (check firejail — see Problem 4). The frame cache is at `~/.cache/caelestia-live-frame.jpg`.

**Q: The wallpaper doesn't come back after reboot.**  
Check that `wallpaper-startup.sh` is exec'd from your Hyprland config and that `~/.local/state/caelestia/wallpaper/is_live_wallpaper_active` exists.

**Q: Can I use this on GNOME/KDE?**  
mpvpaper is Wayland-native and works best with Hyprland/Sway. For other compositors, check mpvpaper's [compatibility list](https://github.com/GhostNaN/mpvpaper#compatibility).

**Q: Why 30fps instead of 60fps for transcoding?**  
mpvpaper copies each decoded frame from GPU RAM to the EGL surface. At 30fps that copy runs half as often — imperceptible on a background wallpaper, but halves the overhead.

---

## 📜 License

Scripts are free to use and modify. If you improve something, a PR is welcome.

---

<div align="center">
Made for <a href="https://github.com/caelestia-dots">Caelestia</a> · Runs on <a href="https://hyprland.org">Hyprland</a> · Powered by <a href="https://github.com/GhostNaN/mpvpaper">mpvpaper</a>
</div>
