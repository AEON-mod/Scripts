# Collage Banner Generator

A Python script to generate a beautifully arranged, rotated, and tiled collage banner from a folder of images. It can generate high-quality static PNG banners, smoothly animated GIF banners, or both.

## Prerequisites

To run this script, you will need Python 3 and the `Pillow` library installed on your system.

### Installation

#### Ubuntu / Debian / Linux Mint
```bash
sudo apt update
sudo apt install python3 python3-pip python3-pil
```
*(Alternatively, you can install Pillow via pip: `pip3 install Pillow`)*

#### Fedora / RHEL / CentOS
```bash
sudo dnf install python3 python3-pip python3-pillow
```

#### Arch Linux / Manjaro
```bash
sudo pacman -S python python-pip python-pillow
```

#### macOS (using Homebrew)
```bash
brew install python
pip3 install Pillow
```

#### Windows
Install Python from the Microsoft Store or [python.org](https://www.python.org/). Then open Command Prompt or PowerShell and run:
```cmd
pip install Pillow
```

## How to Use

You can run the script in two ways:

**1. By providing the path directly**
```bash
python3 /path/to/your/script/collage_banner.py /path/to/your/images
```

**2. By navigating to the directory first**
```bash
cd /path/to/your/images
python3 /path/to/your/script/collage_banner.py
```

When you run the script, it will interactively prompt you to choose the output format:
```text
Select output format:
1. Create .gif
2. Create .png
3. Create both
Enter 1, 2, or 3: 
```
Simply type your choice and press Enter. The script will save the generated `banner.png` and/or `banner.gif` in the target folder.
