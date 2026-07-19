<div align="center">
  <h1>✨ Dynamic Wallpaper Transcoder</h1>
  <p><i>Automatically detects your system's resolution and transcodes wallpapers to perfectly match, maximizing visual fidelity while preserving battery.</i></p>
</div>

---

## ⚡ Features
- **Dynamic Resolution Detection**: Probes your system via `xrandr` to find your active screen resolution (e.g. `3840x2160`, `2560x1440`, `1920x1080`).
- **Smart Scaling**: Automatically upscales smaller videos or downscales larger ones to perfectly fit your detected resolution while maintaining the aspect ratio.
- **Battery & Resource Optimized**: Automatically caps all videos at `30fps`. A 144Hz wallpaper might look cool, but it drains laptop batteries extremely fast. 30fps is the perfect sweet spot for smooth animated backgrounds.
- **Flawless Quality**: Utilizes NVIDIA NVENC with maximum quality presets (`p7` and `cq 15`) and libx264 software fallback (`slow` and `crf 16`) to ensure the final result has no compression artifacts.

## 🚀 Usage
Simply run the script. By default, it will process all videos in `$HOME/Pictures/Wallpapers/Animated`.

```bash
bash dynamic-transcoder.sh
```
