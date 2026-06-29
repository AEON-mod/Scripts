# 🎬 mpvpaper Live Wallpaper — Hyprland Setup Guide

> **Smooth, GPU-decoded video wallpapers on Hyprland/Wayland with near-zero CPU overhead.**
> This guide documents every pitfall encountered and how to fix them, so you don't have to.

---

## 📋 Table of Contents
- [Requirements](#requirements)
- [Installation](#installation)
- [The Problems You'll Hit (And Their Fixes)](#the-problems-youll-hit-and-their-fixes)
- [Scripts](#scripts)
- [Power Management](#power-management)
- [Usage](#usage)
- [Benchmarks](#benchmarks)

---

## Requirements

| Package | Purpose |
|---------|---------|
| `mpvpaper` | Renders video as Wayland wallpaper via libmpv |
| `ffmpeg` | Video transcoding (use `/usr/bin/ffmpeg` — see pitfalls) |
| `nvidia-utils` | NVENC/NVDEC GPU codec support |
| `legion-linux` *(optional)* | Fan control on Lenovo Legion laptops |

```bash
# Arch / Hyprland
sudo pacman -S mpvpaper ffmpeg nvidia-utils
```

---

## Installation

```bash
# 1. Clone this repo
git clone https://github.com/AEON-mod/Scripts.git ~/GitHub/personal/Scripts

# 2. Copy the scripts to your config
mkdir -p ~/.config/hypr/scripts
cp mpvpaper-live-wallpaper/live-wallpaper.sh ~/.config/hypr/scripts/
cp mpvpaper-live-wallpaper/transcode-wallpapers.sh ~/Pictures/Wallpapers/
chmod +x ~/.config/hypr/scripts/live-wallpaper.sh
chmod +x ~/Pictures/Wallpapers/transcode-wallpapers.sh

# 3. Put your wallpaper videos here
mkdir -p ~/Pictures/Wallpapers/live-wallpaper
# (copy your .mp4 / .webm / .mkv files here)

# 4. Transcode them to 1080p30 for optimal performance (CRITICAL — see below)
bash ~/Pictures/Wallpapers/transcode-wallpapers.sh

# 5. Launch!
bash ~/.config/hypr/scripts/live-wallpaper.sh
```

---

## The Problems You'll Hit (And Their Fixes)

### ❌ Problem 1: CPU at 90%+ with `vf=scale`

**Symptom:** mpvpaper uses 80–90% CPU, fans max out, temps hit 87–89°C.

**Cause:** Using `vf=scale=1920:1080` in mpvpaper options. This runs a **software** scale filter on every decoded frame at full framerate — on CPU.

**Fix:** Remove `vf=scale` entirely. The Wayland compositor handles display scaling natively at zero CPU cost. mpvpaper already fills the screen via `panscan=1.0`.

```bash
# ❌ Wrong
mpvpaper -o "hwdec=nvdec vf=scale=1920:1080" '*' video.mp4

# ✅ Correct
mpvpaper -s -o "loop=yes hwdec=nvdec-copy hwdec-codecs=all mute=yes panscan=1.0" '*' video.mp4
```

---

### ❌ Problem 2: `nvdec` fails silently, falls back to CPU decode

**Symptom:** You set `hwdec=nvdec` but CPU is still at 90%+. GPU shows 0% utilization.

**Cause:** mpvpaper uses a **libmpv EGL surface** (not a native dmabuf surface). Pure `nvdec` requires zero-copy GPU→compositor frame handoff which needs dmabuf. Since mpvpaper's surface can't do that, mpv silently falls back to software decode.

**Fix:** Use `hwdec=nvdec-copy` instead. This decodes on GPU, copies to RAM, then uploads to EGL. Not as efficient as true zero-copy but still dramatically better than full software decode.

```bash
# ❌ Wrong — silently falls back to CPU on mpvpaper
hwdec=nvdec

# ✅ Correct for mpvpaper's EGL architecture
hwdec=nvdec-copy hwdec-codecs=all
```

---

### ❌ Problem 3: Playing 4K video on a 1080p screen

**Symptom:** Even with `nvdec-copy`, CPU sits at 35–50%, drops frames constantly.

**Cause:** Your screen is 1920×1080 but the video is 3840×2160 (4K) or 2560×1440 (1440p). The GPU decodes **4× more pixels** than needed, then copies that massive frame to RAM. The Wayland compositor then scales it down — 4× wasted work every frame at 60fps.

**Fix:** Pre-transcode all wallpaper videos to your screen resolution (1080p) at 30fps using NVENC. Run `transcode-wallpapers.sh` — it does this automatically.

```bash
bash ~/Pictures/Wallpapers/transcode-wallpapers.sh
```

Results after transcoding 4K → 1080p30:
- CPU: 90% → **~22%**
- Temps: 87°C → **~65°C**
- Frame drops: 200+ → **0**
- File sizes: reduced by 60–90%

---

### ❌ Problem 4: `ffmpeg`/`ffprobe` wrapped in firejail

**Symptom:** `ffprobe` returns "Permission denied" on perfectly readable files. `ffmpeg` fails mysteriously.

**Cause:** `/usr/local/bin/ffmpeg` and `/usr/local/bin/ffprobe` are symlinks to `/usr/bin/firejail`. Firejail sandboxes filesystem access and blocks CUDA/GPU passthrough.

**Fix:** Always call the real binaries directly:
```bash
# ❌ Firejailed versions (avoid)
ffmpeg ...
ffprobe ...

# ✅ Real binaries (use these)
/usr/bin/ffmpeg ...
/usr/bin/ffprobe ...
```

Or check which is which:
```bash
which ffmpeg          # might show /usr/local/bin/ffmpeg → firejail
ls -la /usr/bin/ffmpeg   # real ffmpeg binary
```

---

### ❌ Problem 5: CPU power limits set incorrectly (200W PL1!)

**Symptom:** System runs hot even at idle. `constraint_0` shows an absurd value.

**Cause:** Some tools write to the wrong powercap constraint. On Intel 12th gen:
- `constraint_0` = **PL1** (long_term sustained — should be ≤ hardware max)
- `constraint_1` = **PL2** (short_term burst — can be slightly higher)

**Fix:** Use `game-mode.sh` to set correct values, and install a boot service so they persist:

```bash
sudo bash ~/.scripts/game-mode.sh off   # sets PL1=45W PL2=55W

# Install boot persistence
sudo cp cpu-power-limits.service /etc/systemd/system/
sudo systemctl enable --now cpu-power-limits.service
```

---

### ❌ Problem 6: Fans stuck at max speed

**Symptom:** Fans never slow down even after temps drop.

**Cause:** `legion_cli maximumfanspeed-enable` was called (usually by a game launcher script) and never disabled.

**Fix:**
```bash
sudo legion_cli maximumfanspeed-disable
```

Add this to your game-off script so it always resets.

---

## Scripts

| Script | Location | Purpose |
|--------|----------|---------|
| `live-wallpaper.sh` | `~/.config/hypr/scripts/` | Launch/cycle video wallpapers |
| `transcode-wallpapers.sh` | `~/Pictures/Wallpapers/` | Batch convert videos to 1080p30 |
| `game-mode.sh` | `~/.scripts/` | Power profiles (gaming/balanced/wallpaper) |

---

## Power Management

Three power modes available via `game-mode.sh`:

| Mode | PL1 (sustained) | PL2 (burst) | EPP | Fans | Use when |
|------|----------------|-------------|-----|------|----------|
| `on` | 55W (hw max) | 65W | performance | max | Gaming |
| `off` | 45W | 55W | balance_performance | auto | Normal desktop |
| `wallpaper` | 35W | 45W | balance_power | auto | Live wallpaper running |

```bash
sudo bash ~/.scripts/game-mode.sh on        # gaming
sudo bash ~/.scripts/game-mode.sh off       # balanced (default)
sudo bash ~/.scripts/game-mode.sh wallpaper # coolest + quietest
```

To allow running without password:
```bash
echo 'yourusername ALL=(root) NOPASSWD: /home/yourusername/.scripts/game-mode.sh, /usr/bin/legion_cli' \
  | sudo tee /etc/sudoers.d/power-mode
sudo chmod 440 /etc/sudoers.d/power-mode
```

---

## Usage

```bash
# Play next wallpaper in rotation
bash ~/.config/hypr/scripts/live-wallpaper.sh

# Play a specific video
bash ~/.config/hypr/scripts/live-wallpaper.sh ~/Pictures/Wallpapers/live-wallpaper/video.mp4

# Stop wallpaper
killall mpvpaper

# Add to Hyprland keybind (hyprland.conf)
bind = $mainMod, W, exec, bash ~/.config/hypr/scripts/live-wallpaper.sh
```

---

## Benchmarks

Tested on: **Lenovo Legion / Intel i7-12650HX / RTX 4050 Laptop / 1920×1080**

| Scenario | CPU % | GPU % | Temp | Dropped Frames |
|----------|-------|-------|------|----------------|
| 4K60 + `vf=scale` + `nvdec-copy` | **93.9%** | 6% | **87–89°C** | 200+ |
| 4K60 + no `vf=scale` + `nvdec-copy` | ~45% | 6% | ~80°C | ~50 |
| **1080p30 + `nvdec-copy` (recommended)** | **~22%** | **1%** | **~65°C** | **0** |

> **TL;DR:** Transcode to 1080p30, use `nvdec-copy`, never use `vf=scale`. That's it.

---

## Credits

Figured out through hours of debugging on Hyprland + Wayland + NVIDIA Optimus.
Shared so no one else has to suffer through the same issues.
