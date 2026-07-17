<div align="center">
  <h1>🧠 AI Wallpaper Renamer</h1>
  <p><i>Automatically rename messy wallpaper image files into aesthetic, descriptive names using Vision-Language Models.</i></p>
</div>

---

## ⚡ What is it?
Tired of generic, meaningless wallpaper names like `image_1234.jpg`, `download(1).png`, or `FB_IMG_89283.jpg`? 

This script uses the **BLIP** (Bootstrapping Language-Image Pre-training) Vision-Language Model to "look" at your wallpapers and generate intelligent, descriptive, and clean filenames.

### ✨ Key Features
- **AI Vision Analysis**: Runs the BLIP base model locally to generate a caption for the image contents.
- **Aesthetic Text Filtering**: Cleans the AI output by removing stop words and substituting generic terms (e.g., replaces "woman"/"man" with "girl"/"boy" for a stylized naming convention).
- **Format Normalization**: Standardizes your wallpaper directory by converting various formats (`.png`, `.webp`, `.bmp`) to high-quality `JPEG` (95% quality).
- **Collision Protection**: Automatically prevents overwrites by appending numerical counters (`_01`, `_02`) to images that end up with the same generated name.
- **Recursive Scanning**: Process nested directories and subfolders with ease.

## 🛠️ Installation & Requirements
Requires Python 3, PyTorch, Transformers, and Pillow. An NVIDIA GPU (CUDA) is highly recommended for reasonable processing speeds.
```bash
pip install torch transformers pillow
```

## 🚀 Usage
Pass the directory containing your wallpapers as an argument:
```bash
python wallpaper_renamer.py /path/to/wallpapers
```

## 🐛 Troubleshoot
- **`CUDA out of memory` / No GPU**: Ensure your PyTorch installation supports CUDA. If you do not have a dedicated GPU, you can edit the script to change `.to("cuda")` to `.to("cpu")` (note: processing will take significantly longer).
- **Errors processing specific files**: Broken, corrupted, or unsupported images will automatically be skipped and a final error tally will be reported at the end of the script execution.

## 📝 Disclaimer
I wrote this script myself to streamline my workflow. Feel free to use, modify, and distribute it as you see fit—treat it just like open-source software!
