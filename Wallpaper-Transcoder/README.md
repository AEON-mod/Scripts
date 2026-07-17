<div align="center">
  <h1>🎥 Wallpaper Transcoder</h1>
  <p><i>Effortlessly transcode high-res/high-fps videos to 1080p@30fps and convert GIFs to MP4s via NVENC Hardware Acceleration.</i></p>
</div>

---

## ⚡ What is it?
A smart batch transcoder designed to optimize animated wallpapers for `mpvpaper`. It prevents wasted GPU resources and battery drain by scaling down overkill 4K/60fps videos and fixing GIF loops.

## 🛠️ Installation & Requirements
Requires `ffmpeg` compiled with NVENC (NVIDIA GPU encoding) support.
```bash
sudo pacman -S ffmpeg
```

## 🚀 Usage
Simply execute the script in your terminal. It will automatically process supported video formats.
```bash
bash transcode-wallpapers.sh
```

## 🐛 Troubleshoot
- **`NVENC failed`**: The script automatically falls back to CPU encoding (libx264) if your GPU doesn't support NVENC or if the drivers aren't loaded.
- **GIFs show as static**: `mpvpaper` struggles with GIFs. This script natively converts them to perfect MP4 loops to fix this.

## 📄 License
This project is licensed under the [MIT License](LICENSE).
