<div align="center">
  <h1>🎥 Wallpaper Transcoder</h1>
  <p><i>Effortlessly transcode high-res/high-fps videos to 1080p@30fps and convert GIFs to MP4s via NVENC Hardware Acceleration.</i></p>
</div>

---

## ⚡ What is it?
A smart batch transcoder designed to optimize animated wallpapers for desktop wallpaper engines like `mpvpaper`. Using ultra-high-resolution (e.g., 4K) or high-framerate (e.g., 60fps) videos as desktop backgrounds wastes significant GPU resources and memory bandwidth.

This script elegantly solves that problem by:
- **Downscaling**: Automatically capping videos to `1080p` and `30fps`, saving resources without sacrificing noticeable desktop quality.
- **Hardware Acceleration**: Leveraging Nvidia's NVENC hardware encoder to transcode rapidly without stressing the CPU.
- **GIF Optimization**: Wallpaper engines often struggle to seamlessly loop GIF files. This script intelligently converts GIFs to standard MP4s using a two-pass palette extraction method, ensuring 100% color accuracy and perfect looping.
- **Safe Backup**: Preserves your original uncompressed files in a dedicated `original/` subfolder.
- **Smart Skipping**: Automatically skips already transcoded files, making it safe to run multiple times when adding new wallpapers.

## 🛠️ Installation & Requirements
Requires `ffmpeg` compiled with NVENC (NVIDIA GPU encoding) support.

<img src="https://cdn.simpleicons.org/debian/A81D33" width="16" /> Debian / <img src="https://cdn.simpleicons.org/ubuntu/E95420" width="16" /> Ubuntu
```bash
sudo apt update && sudo apt install -y ffmpeg
```
<img src="https://cdn.simpleicons.org/fedora/51A2DA" width="16" /> Fedora
```bash
sudo dnf install -y ffmpeg
```
<img src="https://cdn.simpleicons.org/archlinux/1793D1" width="16" /> Arch Linux
```bash
sudo pacman -S --noconfirm ffmpeg
```

## 🚀 Usage
Simply execute the script in your terminal. By default, it looks for files in `$HOME/Pictures/Wallpapers/Animated`.
```bash
bash transcode-wallpapers.sh
```

## 🐛 Troubleshoot
- **`NVENC failed`**: The script automatically falls back to CPU encoding (libx264) if your GPU doesn't support NVENC or if the proprietary drivers aren't loaded.
- **GIFs show as static**: This is a known issue with `mpvpaper`. Ensure you are running this script to convert them to `.mp4` files.
- **Out of space**: Check the `original/` folder! Once you are satisfied with the transcoded files, you can safely delete the `original/` folder to free up disk space.

## 📝 Disclaimer & License
This script is provided "as is", without warranty of any kind. I built this tool for personal use, but I am releasing it as open-source under the **MIT License**. 

You are completely free to use, modify, and distribute it. See the [LICENSE](LICENSE) file for more details.
