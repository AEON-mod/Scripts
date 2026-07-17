<div align="center">
  <h1>✨ Desktop Utilities</h1>
  <p><i>A collection of aesthetic and functional automation scripts for Linux desktop customization.</i></p>
</div>

---

## 📦 Included Tools

### 1. Wallpaper Transcoder
Optimizes animated wallpapers for `mpvpaper` by transcoding 4K/60fps videos to 1080p/30fps utilizing hardware acceleration (NVENC), significantly saving battery and GPU resources. It also perfectly converts GIFs to MP4 format for seamless looping.

**Installation & Requirements:**
```bash
# Requires ffmpeg with NVENC support
sudo pacman -S ffmpeg
```
**Usage:**
```bash
bash wallpaper-transcoder/transcode-wallpapers.sh
```

### 2. AI Wallpaper Renamer
Employs the BLIP Vision-Language Model (VLM) to analyze and automatically rename messy wallpaper image files into clean, descriptive, and aesthetic names. 

**Installation & Requirements:**
```bash
# Requires Python and ML dependencies
pip install torch transformers pillow
```
**Usage:**
```bash
python ai-wallpaper-renamer/wallpaper_renamer.py /path/to/wallpapers
```

### 3. Universal Cursor Installer
A seamless script that installs Linux (X11) cursor themes directly, and magically converts and installs Windows cursor themes (`.ani`/`.cur`) into native Linux formats for your environment.

**Installation & Requirements:**
```bash
pip install win2xcur
```
**Usage:**
```bash
bash cursor-installer/convert_cursors.sh /path/to/theme/folder
```

---

<div align="center">
<i>Crafted for a better desktop experience.</i>
</div>
