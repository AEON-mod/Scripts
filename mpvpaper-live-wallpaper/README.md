<div align="center">

# 🎬 mpvpaper Live Wallpaper

**GPU-accelerated video wallpapers for Hyprland — with full [Caelestia](https://github.com/caelestia-dots) integration**

[![Hyprland](https://img.shields.io/badge/Hyprland-Wayland-blue?style=flat-square&logo=wayland)](https://hyprland.org)
[![mpvpaper](https://img.shields.io/badge/mpvpaper-1.8+-orange?style=flat-square)](https://github.com/GhostNaN/mpvpaper)
[![GPU](https://img.shields.io/badge/GPU-NVDEC%20accelerated-76b900?style=flat-square&logo=nvidia)](https://developer.nvidia.com)
[![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?style=flat-square&logo=gnubash)](https://www.gnu.org/software/bash/)

Play any `.mp4 / .webm / .mkv` as your live desktop wallpaper with hardware decoding,  
automatic Caelestia color scheme extraction, and smooth cycling — running at ~20% CPU.

</div>

---

## ✨ Features

- 🎮 **NVDEC hardware decoding** — GPU handles decode, your CPU stays free
- 🔄 **One-key wallpaper cycling** — press the keybind to jump to the next video
- 🎨 **Caelestia color extraction** — updates your shell/widget theme from a video frame automatically
- 🔋 **Auto-pause when covered** — mpvpaper stops rendering when windows cover it (saves power)
- 💾 **Persists across reboots** — startup script restores your last video on every login
- 🎬 **Batch transcoder included** — downscales 4K/1440p to your screen res in one command
- 🖼 **Coexists with image wallpapers** — switching back to a static image via Caelestia works seamlessly
- 🕹 **Wallpaper Engine compatible** — coexists cleanly with `linux-wallpaperengine` scenes

---

## 📋 Requirements

| Package | Why it's needed |
|---------|----------------|
| `mpvpaper` | Renders the video as a Wayland layer-surface wallpaper |
| `ffmpeg` | Extracts a frame from the video for color scheme generation |
| `jq` | Edits `~/.config/caelestia/shell.json` to toggle Caelestia's image layer |
| `caelestia` | Generates the color scheme from the extracted frame |
| `hyprctl` | Auto-detects screen resolution for transcoding |
| `python3` | Used in transcode script for JSON parsing |

> **Note:** `caelestia` is part of the [Caelestia dotfiles](https://github.com/caelestia-dots/caelestia). If you're not using Caelestia, see the [Non-Caelestia setup](#-using-without-caelestia) section.

### Install dependencies

```bash
# Arch / CachyOS / EndeavourOS (AUR for mpvpaper)
sudo pacman -S ffmpeg jq python
yay -S mpvpaper        # or paru -S mpvpaper
```

---

## 📁 Files in this repo

```
mpvpaper-live-wallpaper/
├── live-wallpaper.sh          ← Main script: launch / cycle video wallpapers
├── wallpaper-hook.sh          ← Caelestia post-hook: routes image/video/scene wallpapers
├── wallpaper-startup.sh       ← Startup script: restores last wallpaper on boot
├── transcode-wallpapers.sh    ← Batch downscale 4K/1440p → your screen res via NVENC
├── game-mode.sh               ← (optional) Power profile switcher for NVIDIA laptops
├── cpu-power-limits.service   ← (optional) Systemd service to persist CPU TDP limits
└── README.md
```

**Where files go on your system:**
```
~/.config/hypr/scripts/live-wallpaper.sh          ← copy this
~/.config/hypr/scripts/wallpaper-hook.sh          ← copy this (replaces Caelestia's default)
~/.config/hypr/scripts/wallpaper-startup.sh       ← copy this (replaces Caelestia's default)
~/Pictures/Wallpapers/live-wallpaper/             ← drop your video files here
~/.config/caelestia/cli.json                      ← register the post-hook (Step 4)
~/.config/caelestia/hypr-user.conf                ← add exec-once + keybind (Step 5)
```

---

## 🚀 Installation (Caelestia users)

Follow these steps **in order**.

---

### Step 1 — Install dependencies

```bash
sudo pacman -S ffmpeg jq python
yay -S mpvpaper
```

Verify:
```bash
mpvpaper --help 2>&1 | grep -i version   # should show mpvpaper 1.x
ffmpeg -version | head -1
jq --version
```

---

### Step 2 — Clone this repo

```bash
git clone git@github.com:AEON-mod/Scripts.git ~/Scripts-tmp
# or via HTTPS:
git clone https://github.com/AEON-mod/Scripts.git ~/Scripts-tmp
```

---

### Step 3 — Copy the scripts

```bash
mkdir -p ~/.config/hypr/scripts

cp ~/Scripts-tmp/mpvpaper-live-wallpaper/live-wallpaper.sh     ~/.config/hypr/scripts/
cp ~/Scripts-tmp/mpvpaper-live-wallpaper/wallpaper-hook.sh     ~/.config/hypr/scripts/
cp ~/Scripts-tmp/mpvpaper-live-wallpaper/wallpaper-startup.sh  ~/.config/hypr/scripts/

chmod +x ~/.config/hypr/scripts/live-wallpaper.sh
chmod +x ~/.config/hypr/scripts/wallpaper-hook.sh
chmod +x ~/.config/hypr/scripts/wallpaper-startup.sh
```

> **Why overwrite Caelestia's hook scripts?**  
> Caelestia ships its own `wallpaper-hook.sh` and `wallpaper-startup.sh` in  
> `~/.local/share/caelestia/hypr/scripts/` — but these are the **source files** that get  
> symlinked or copied to `~/.config/hypr/scripts/`. The versions in this repo are  
> drop-in replacements that add video wallpaper routing while keeping all original  
> image + Wallpaper Engine behaviour intact.

---

### Step 4 — Register the post-hook in Caelestia

Caelestia needs to know which script to call after every wallpaper change.  
Edit (or create) `~/.config/caelestia/cli.json`:

```bash
# If the file already exists, check its current content first:
cat ~/.config/caelestia/cli.json
```

Set it to:
```json
{
    "wallpaper": {
        "postHook": "/home/YOUR_USERNAME/.config/hypr/scripts/wallpaper-hook.sh"
    }
}
```

> **Replace `YOUR_USERNAME`** with your actual username, or use the full expanded path.  
> You can get it with: `echo $HOME`

Quick one-liner (replaces the whole file):
```bash
echo "{\"wallpaper\":{\"postHook\":\"$HOME/.config/hypr/scripts/wallpaper-hook.sh\"}}" \
  | jq . > ~/.config/caelestia/cli.json
```

---

### Step 5 — Add the startup exec and keybind to Hyprland

Edit `~/.config/caelestia/hypr-user.conf` (this is the safe user-override file that  
Caelestia sources at the end of its config — it won't be overwritten by Caelestia updates):

```bash
nano ~/.config/caelestia/hypr-user.conf
```

Add these two lines:
```conf
exec-once = ~/.config/hypr/scripts/wallpaper-startup.sh

# Live wallpaper: cycle to next video
bind = SUPER ALT, W, exec, ~/.config/hypr/scripts/live-wallpaper.sh
```

> **Keybind:** `Super + Alt + W` cycles to the next video wallpaper.  
> Change `SUPER ALT, W` to whatever you prefer.  
> To play a specific file: `bind = ..., exec, ~/.config/hypr/scripts/live-wallpaper.sh /path/to/video.mp4`

---

### Step 6 — Create the wallpaper directory and add videos

```bash
mkdir -p ~/Pictures/Wallpapers/live-wallpaper
```

Drop any `.mp4`, `.webm`, or `.mkv` files inside. If you have 4K or 1440p videos, transcode them first (Step 7) — skipping this causes ~90% CPU usage.

---

### Step 7 — (Recommended) Transcode high-res videos

If your videos are larger than your screen resolution, transcode them down. This is the single biggest performance improvement — drops CPU from ~90% to ~20%:

```bash
bash ~/Scripts-tmp/mpvpaper-live-wallpaper/transcode-wallpapers.sh
```

What it does:
- Auto-detects your screen resolution via `hyprctl monitors`
- Skips videos already at or below your screen size
- Transcodes in 3 priority paths: **Full GPU** (CUDA+NVENC) → **CPU decode + NVENC** → **CPU-only** (fallback)
- Saves originals as `.orig.mp4` so nothing is lost
- Re-run anytime you add new wallpapers

Manual resolution override:
```bash
bash transcode-wallpapers.sh 1920 1080   # force 1080p
bash transcode-wallpapers.sh 2560 1440   # force 1440p
```

---

### Step 8 — Reload Hyprland

```bash
hyprctl reload
```

Then press **`Super + Alt + W`** — your first video wallpaper should start playing.

---

## 🎮 Daily Usage

```bash
# Cycle to the next video
Super + Alt + W        (the keybind you set)

# Or run the script directly
bash ~/.config/hypr/scripts/live-wallpaper.sh

# Play a specific video
bash ~/.config/hypr/scripts/live-wallpaper.sh ~/Pictures/Wallpapers/live-wallpaper/city.mp4

# Stop the live wallpaper
killall mpvpaper

# Switch back to a static image (use Caelestia normally — it kills mpvpaper automatically)
caelestia wallpaper -f ~/Pictures/Wallpapers/some-image.jpg

# Add a new video then transcode everything at once
cp newvideo.mp4 ~/Pictures/Wallpapers/live-wallpaper/
bash ~/Scripts-tmp/mpvpaper-live-wallpaper/transcode-wallpapers.sh
```

---

## 🔗 How It Works with Caelestia

The integration uses a custom `postHook` and an env-var guard to prevent Caelestia's  
wallpaper system from killing the video that's already playing:

```
Super+Alt+W pressed
    └─► live-wallpaper.sh
            ├─ Kills existing mpvpaper / linux-wallpaperengine
            ├─ shell.json → wallpaperEnabled: false    (hides Caelestia's image layer)
            ├─ Writes is_live_wallpaper_active flag
            ├─ Launches mpvpaper with nvdec-copy
            ├─ ffmpeg extracts one frame → ~/.cache/caelestia-live-frame.jpg
            └─ LIVE_WALLPAPER_COLORS_ONLY=1 caelestia wallpaper -f <frame>
                    └─► wallpaper-hook.sh
                            └─ Sees env var = 1 → exits immediately
                               (color scheme updates, mpvpaper keeps playing ✅)

Caelestia wallpaper picker used normally (image selected)
    └─► wallpaper-hook.sh
            ├─ Kills mpvpaper
            ├─ Removes is_live_wallpaper_active flag
            └─ shell.json → wallpaperEnabled: true     (re-enables Caelestia's image layer)

Hyprland starts / session restored
    └─► wallpaper-startup.sh (exec-once)
            ├─ is_live_wallpaper_active exists?
            │       Yes → re-runs live-wallpaper.sh with the saved video path
            └─ No → reads path.txt → re-applies last static wallpaper via wallpaper-hook.sh
```

---

## ⚡ Performance Guide

### The 4 problems people hit — and their fixes

#### ❌ Problem 1 — `vf=scale` destroys your CPU

**Symptom:** 80–94% CPU, fans max out immediately on wallpaper start.

**Cause:** `vf=scale=WxH` forces software scaling — a CPU filter that runs on **every decoded frame** at full framerate. The Wayland compositor already scales natively for free.

```bash
# ❌ Wrong — spikes CPU to 90%+
mpvpaper -o "hwdec=nvdec vf=scale=1920:1080" '*' video.mp4

# ✅ Correct — compositor scales natively, zero CPU cost
mpvpaper -s -o "loop=yes hwdec=nvdec-copy hwdec-codecs=all mute=yes panscan=1.0" '*' video.mp4
```

---

#### ❌ Problem 2 — `hwdec=nvdec` silently falls back to software decode

**Symptom:** You set `hwdec=nvdec` but `nvidia-smi` shows 0% decode usage, CPU still at 90%.

**Cause:** mpvpaper uses a **libmpv EGL surface**, not a native dmabuf surface. Pure `nvdec` requires zero-copy GPU→compositor handoff via dmabuf — which EGL can't provide. mpv silently falls back to software without any warning.

**Fix:** Use `nvdec-copy` — decodes on GPU, copies frame to system RAM for EGL upload. Not zero-copy, but still **dramatically better** than full software decode.

```bash
# ❌ Silently uses CPU decode on mpvpaper
hwdec=nvdec

# ✅ GPU decode → RAM copy → EGL upload (correct for mpvpaper)
hwdec=nvdec-copy hwdec-codecs=all
```

> **`hwdec-codecs=all`** removes mpv's default whitelist (H.264 + HEVC only) so VP9, AV1, and others also use the GPU.

---

#### ❌ Problem 3 — Playing 4K video on a 1080p screen

**Symptom:** Even with `nvdec-copy`, CPU sits at 35–50%, frames drop constantly.

**Cause:** Your GPU decodes 4× more pixels than your screen can show. That oversized frame gets copied to RAM and scaled by the compositor — 4× wasted work, 60 times per second.

**Fix:** Pre-transcode to your screen resolution (see Step 7). Results:

| Metric | 4K60 naive | 1080p30 transcoded ✅ |
|--------|-----------|----------------------|
| CPU | ~90% | **~20%** |
| Temps | ~87°C | **~65°C** |
| Dropped frames | 200+/min | **0** |
| File size | 100% | **10–30%** |

---

#### ❌ Problem 4 — ffmpeg / ffprobe wrapped in Firejail

**Symptom:** `ffmpeg` returns "Permission denied" on files you can read normally. Frame extraction fails silently.

**Cause:** Some distros/setups symlink `/usr/local/bin/ffmpeg` → `/usr/bin/firejail`. Firejail sandboxes filesystem and GPU access.

```bash
# Check if you're affected
ls -la $(which ffmpeg)
# Output → /usr/bin/firejail ? You're affected.
```

**Fix:** The transcode script auto-detects and calls `/usr/bin/ffmpeg` directly. If `live-wallpaper.sh` frame extraction fails on your system, replace `ffmpeg` with `/usr/bin/ffmpeg` in the script.

---

## 📊 Benchmarks

> Tested on: **Intel i7-12650HX · RTX 4050 Laptop · 1920×1080 · Hyprland · CachyOS**

| Scenario | CPU % | GPU % | Temp | Dropped Frames |
|----------|-------|-------|------|----------------|
| 4K60 + `vf=scale` + `nvdec-copy` | ~94% | low | 87–89°C | 200+/min |
| 4K60, no `vf=scale`, `nvdec-copy` | ~45% | low | ~80°C | ~50/min |
| **1080p30 + `nvdec-copy`** ✅ | **~20%** | medium | **~65°C** | **0** |

---

## 🖥 Using Without Caelestia

If you're running vanilla Hyprland (without Caelestia), use a simplified version:

### 1 — Copy only `live-wallpaper.sh` and `transcode-wallpapers.sh`

```bash
mkdir -p ~/.config/hypr/scripts
cp live-wallpaper.sh ~/.config/hypr/scripts/
chmod +x ~/.config/hypr/scripts/live-wallpaper.sh
```

### 2 — Edit `live-wallpaper.sh` to remove Caelestia-specific sections

Remove or comment these blocks:
```bash
# Remove these lines (Caelestia-specific):
FLAG_FILE=...
SHELL_CONF=...
touch "$FLAG_FILE"
jq '.background.wallpaperEnabled = false' ...
FRAME_CACHE=...
ffmpeg ... "$FRAME_CACHE"
LIVE_WALLPAPER_COLORS_ONLY=1 caelestia wallpaper -f "$FRAME_CACHE"
```

Keep everything else — the mpvpaper launch command is universal.

### 3 — Add to `hyprland.conf`

```conf
exec-once = bash ~/.config/hypr/scripts/live-wallpaper.sh   # auto-start on login
bind = SUPER ALT, W, exec, bash ~/.config/hypr/scripts/live-wallpaper.sh
```

---

## ❓ FAQ

**Q: Does this work on AMD GPUs?**  
Replace `hwdec=nvdec-copy` with `hwdec=vaapi-copy`. In `transcode-wallpapers.sh`, change `h264_nvenc` → `h264_vaapi` and remove `-hwaccel cuda -hwaccel_output_format cuda` from Path A.

**Q: Does this work without a dedicated GPU?**  
Yes. Use `hwdec=auto` in the mpvpaper options. For transcoding, Path C (CPU fallback) will handle it automatically.

**Q: My color scheme doesn't update when I set a live wallpaper.**  
Run `bash ~/.config/hypr/scripts/live-wallpaper.sh` from a terminal and check for errors. Usually caused by ffmpeg being firejail-wrapped (see Problem 4). Verify `~/.cache/caelestia-live-frame.jpg` exists after running.

**Q: The wallpaper doesn't restore after reboot.**  
Check that `exec-once = ~/.config/hypr/scripts/wallpaper-startup.sh` is in `~/.config/caelestia/hypr-user.conf`. Also verify `~/.local/state/caelestia/wallpaper/is_live_wallpaper_active` exists (it's created when a live wallpaper is set).

**Q: Switching back to a static image via Caelestia doesn't kill the video.**  
Make sure `~/.config/caelestia/cli.json` has the `postHook` pointing to your `wallpaper-hook.sh` (Step 4). Test with: `caelestia wallpaper -f ~/some-image.jpg` — mpvpaper should stop.

**Q: Can I use multiple monitors?**  
mpvpaper's `'*'` argument targets all monitors automatically. Each monitor gets the same video.

**Q: Why 30fps for transcoding instead of 60fps?**  
mpvpaper copies each decoded frame from GPU RAM to the EGL surface. At 30fps this happens half as often — indistinguishable on a background wallpaper, but halves the frame-copy overhead.

**Q: Can I use this on GNOME or KDE?**  
mpvpaper targets Wayland layer-surfaces and works best on compositors that support them (Hyprland, Sway, river). For GNOME/KDE, check mpvpaper's [compatibility list](https://github.com/GhostNaN/mpvpaper#compatibility).

---

## 🗂 State Files Reference

| File | Purpose |
|------|---------|
| `~/.local/state/caelestia/wallpaper/current_live_wallpaper.txt` | Path of the currently playing video |
| `~/.local/state/caelestia/wallpaper/is_live_wallpaper_active` | Flag: exists = live wallpaper is active |
| `~/.local/state/caelestia/wallpaper/path.txt` | Last static image path (managed by Caelestia) |
| `~/.cache/caelestia-live-frame.jpg` | Extracted frame used for color scheme generation |
| `~/.config/caelestia/shell.json` | `background.wallpaperEnabled` toggled by scripts |

---

## 📜 License

Scripts are free to use and modify. PRs welcome.

---

<div align="center">

Made for [Caelestia](https://github.com/caelestia-dots) · Runs on [Hyprland](https://hyprland.org) · Powered by [mpvpaper](https://github.com/GhostNaN/mpvpaper)

</div>
