<div align="center">
  <h1>🎨 Collage Banner Generator</h1>
  <p><i>A beautifully automated tool to generate rotated, tiled collage banners from your image collections.</i></p>

  ![Static Banner](Assets/banner.png)
  <br>
  <p align="center">━━━━━━━ ❖ ━━━━━━━</p>
  <br>
  ![Animated Banner](Assets/banner.gif)
  <br>
  
  [![Python Version](https://img.shields.io/badge/python-3.x-blue.svg?logo=python&logoColor=white)](#)
  [![License](https://img.shields.io/badge/license-MIT-green.svg)](#)
  [![Pillow](https://img.shields.io/badge/dependency-Pillow-orange.svg)](#)
</div>

---

## ✨ Features

- **Dynamic Tiling:** Automatically arranges your images into a stunning, rotated grid.
- **Dual Outputs:** Choose between a **high-resolution static PNG** or a **smoothly animated GIF**.
- **Interactive Prompt:** User-friendly CLI that asks what format you want on the fly.
- **Smart Framing:** Beautifully rounds image corners and applies colorful, vibrant borders automatically.

---

## 🛠️ Prerequisites

To run this script, you will need **Python 3** and the `Pillow` library installed on your system.

### 📦 Installation

<details>
<summary><b>🐧 Ubuntu / Debian / Linux Mint</b></summary>
<br>

```bash
sudo apt update
sudo apt install python3 python3-pip python3-pil
```
*(Alternatively, you can install Pillow via pip: `pip3 install Pillow`)*
</details>

<details>
<summary><b>🎩 Fedora / RHEL / CentOS</b></summary>
<br>

```bash
sudo dnf install python3 python3-pip python3-pillow
```
</details>

<details>
<summary><b>🦅 Arch Linux / Manjaro</b></summary>
<br>

```bash
sudo pacman -S python python-pip python-pillow
```
</details>

<details>
<summary><b>🍎 macOS (using Homebrew)</b></summary>
<br>

```bash
brew install python
pip3 install Pillow
```
</details>

<details>
<summary><b>🪟 Windows</b></summary>
<br>

Install Python from the Microsoft Store or [python.org](https://www.python.org/). Then open Command Prompt or PowerShell and run:
```cmd
pip install Pillow
```
</details>

---

## 🚀 How to Use

You can run the script in two versatile ways. In both cases, the output (`banner.png` and/or `banner.gif`) will be saved directly into the image folder.

### 1️⃣ Navigating to the directory first (Recommended)
Simply change to the directory where your images are located, and run the script:
```bash
cd /path/to/your/images
python3 /path/to/your/script/collage_banner.py
```

### 2️⃣ Providing the path directly
You can also pass the directory path directly as an argument:
```bash
python3 /path/to/your/script/collage_banner.py /path/to/your/images
```

---

## 🎮 Interactive Prompt

Once you run the command, the script will gracefully prompt you to choose the desired output:

```text
Select output format:
1. Create .gif
2. Create .png
3. Create both
Enter 1, 2, or 3: 
```

Just type your choice (`1`, `2`, or `3`) and press **Enter**!

> 💡 **Pro Tip:** Generating a static PNG (Option 2) is incredibly fast as it only renders a single high-resolution frame, while the GIF (Option 1) renders 240 frames for ultra-smooth animation.
