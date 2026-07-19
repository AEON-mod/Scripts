<div align="center">
  <h1>✨ Dynamic Wallpaper Transcoder</h1>
  <p><i>Automatically detects your system's resolution and transcodes wallpapers to perfectly match, maximizing visual fidelity while preserving battery.</i></p>
</div>

---

## ⚡ What is it?
A smart batch transcoder designed to optimize animated wallpapers for desktop wallpaper engines like `mpvpaper`. Using ultra-high-resolution (e.g., 4K) or high-framerate (e.g., 60fps) videos as desktop backgrounds wastes significant GPU resources and memory bandwidth.

This script elegantly solves that problem by:
- **Dynamic Resolution**: Automatically detects your active monitor's resolution (e.g., `3840x2160`, `2560x1440`, `1920x1080`) using `xrandr`.
- **Interactive Multi-Monitor Support**: If you have multiple monitors with DIFFERENT resolutions (e.g., one 4K and one 1080p), the script asks which resolution to target. You can choose a specific one, or choose "ALL". If you choose all, it transcodes the wallpapers into separate subfolders for each resolution perfectly. If it detects only one resolution, it automatically proceeds without asking to save you time.
- **Smart Scaling**: Intelligently upscales low-res videos or downscales high-res videos to perfectly fit your detected resolution while strictly maintaining the aspect ratio.
- **Battery Optimization**: Caps all wallpapers at `30fps`. A 144Hz wallpaper might look cool, but it drains laptop batteries extremely fast. 30fps is the perfect sweet spot for smooth animated backgrounds.
- **Maximum Quality**: Employs the highest quality encoding presets (`p7`/`cq 15` for NVENC, `slow`/`crf 16` for libx264) to ensure the final result has zero compression artifacts. Transcoding takes a little longer, but guarantees pristine visuals.
- **Hardware Acceleration**: Leverages Nvidia's NVENC hardware encoder to transcode rapidly without stressing the CPU.
- **GIF Optimization**: Intelligently converts GIFs to standard MP4s using a two-pass palette extraction method, ensuring 100% color accuracy and perfect looping.
- **Safe Backup**: Preserves your original uncompressed files in a dedicated `original/` subfolder.
- **Smart Skipping**: Automatically skips already transcoded files, making it safe to run multiple times when adding new wallpapers.

## 🛠️ Installation & Requirements
Requires `xrandr` for display detection, and `ffmpeg` compiled with NVENC (NVIDIA GPU encoding) support.

<img src="https://cdn.simpleicons.org/debian/A81D33" width="16" /> Debian / <img src="https://cdn.simpleicons.org/ubuntu/E95420" width="16" /> Ubuntu
```bash
sudo apt update && sudo apt install -y ffmpeg x11-xserver-utils
```
<img src="https://cdn.simpleicons.org/fedora/51A2DA" width="16" /> Fedora
```bash
sudo dnf install -y ffmpeg xorg-x11-server-utils
```
<img src="https://cdn.simpleicons.org/archlinux/1793D1" width="16" /> Arch Linux
```bash
sudo pacman -S --noconfirm ffmpeg xorg-xrandr
```

## 🚀 Usage
Simply execute the script in your terminal. By default, it looks for files in `$HOME/Pictures/Wallpapers/Animated`.
```bash
bash dynamic-transcoder.sh
```

## 🐛 Troubleshoot
- **`Could not detect display resolution dynamically`**: Ensure `xrandr` is installed and you are running a supported display server (X11 or XWayland). It defaults to 1080p if detection fails.
- **`NVENC failed`**: The script automatically falls back to CPU encoding (libx264) if your GPU doesn't support NVENC or if the proprietary drivers aren't loaded.
- **GIFs show as static**: This is a known issue with `mpvpaper`. Ensure you are running this script to convert them to `.mp4` files.
- **Out of space**: Check the `original/` folder! Once you are satisfied with the transcoded files, you can safely delete the `original/` folder to free up disk space.

## 📝 Disclaimer & License
This script is provided "as is", without warranty of any kind. I built this tool for personal use, but I am releasing it as open-source under the **MIT License**. 

You are completely free to use, modify, and distribute it. See the [LICENSE](../LICENSE) file for more details.
