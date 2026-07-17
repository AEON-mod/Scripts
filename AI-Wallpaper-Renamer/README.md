<div align="center">
  <h1>🧠 AI Wallpaper Renamer</h1>
  <p><i>Automatically rename messy wallpaper image files into aesthetic, descriptive names using Vision-Language Models.</i></p>
</div>

---

## ⚡ What is it?
Tired of `image_1234.jpg`? This script uses the BLIP local AI model to look at your wallpapers and give them short, beautiful, and descriptive names (e.g. `aesthetic_anime_girl_city.jpg`) while ensuring zero duplicates.

## 🛠️ Installation & Requirements
Requires Python, PyTorch, Transformers, and Pillow. Make sure you have a CUDA-compatible GPU.
```bash
pip install torch transformers pillow
```

## 🚀 Usage
Pass the directory containing your wallpapers as an argument:
```bash
python wallpaper_renamer.py /path/to/wallpapers
```

## 🐛 Troubleshoot
- **`CUDA out of memory` / No GPU**: Ensure your PyTorch installation supports CUDA. You can change `.to("cuda")` to `.to("cpu")` in the script if you lack an NVIDIA GPU (but it will be much slower).
- **Errors processing specific files**: Broken or unsupported images will automatically be skipped and reported at the end.

## 📄 License
This project is licensed under the [MIT License](LICENSE).
