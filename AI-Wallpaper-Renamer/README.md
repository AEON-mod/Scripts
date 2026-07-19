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
- **Live Wallpaper & GIF Support**: Fully supports video wallpapers (`.mp4`, `.webm`, etc.) and animated `.gif` files by safely extracting frames for captioning while preserving the original animation format.
- **Format Normalization**: Standardizes static image wallpapers by converting various formats (`.png`, `.webp`, `.bmp`) to high-quality `JPEG` (95% quality).
- **Collision Protection**: Automatically prevents overwrites by appending numerical counters (`_01`, `_02`) to files that end up with the same generated name.
- **Recursive Scanning**: Process nested directories and subfolders with ease.

## 🛠️ Installation & Requirements
Requires Python 3, `ffmpeg` (for live wallpaper support), PyTorch, Transformers, and Pillow. An NVIDIA GPU (CUDA) is highly recommended for reasonable processing speeds.

<img src="https://cdn.simpleicons.org/debian/A81D33" width="16" /> Debian / <img src="https://cdn.simpleicons.org/ubuntu/E95420" width="16" /> Ubuntu
```bash
sudo apt update && sudo apt install -y python3 python3-pip ffmpeg
```
<img src="https://cdn.simpleicons.org/fedora/51A2DA" width="16" /> Fedora
```bash
sudo dnf install -y python3 python3-pip ffmpeg
```
<img src="https://cdn.simpleicons.org/archlinux/1793D1" width="16" /> Arch Linux
```bash
sudo pacman -S --noconfirm python python-pip ffmpeg
```

Then install the Python dependencies:
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

## 📝 Disclaimer & License
This script is provided "as is", without warranty of any kind. I built this tool for personal use, but I am releasing it as open-source under the **MIT License**. 

You are completely free to use, modify, and distribute it. See the [LICENSE](LICENSE) file for more details.
