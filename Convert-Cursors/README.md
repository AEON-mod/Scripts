<div align="center">
  <img width="490" height="331" alt="Scrot_23_16-8" src="https://github.com/user-attachments/assets/d607b405-783d-48c9-8613-9f5b46817db5" />

</div>

<div align="center">
  <h1>🖱️ Linux Cursor Toolkit (Convert & Set)</h1>
  <p><i>A seamless toolkit to install, auto-convert Windows `.ani`/`.cur` themes, and easily apply them globally across Hyprland and GTK apps.</i></p>
</div>

---

## ⚡ What is it?
Managing cursor themes on Linux—especially those ported from Windows—is usually a tedious, manual process. Windows uses `.ani` (animated) and `.cur` (static) formats, which Linux compositors cannot read directly.

This toolkit provides two main scripts to completely automate the process:

1. **`convert_cursors.sh` (Installer & Converter)**: 
   - **Format Conversion**: Detects Windows cursor formats and cleanly converts them into X11 format without quality loss using `win2xcur`.
   - **Linux Symlink Mapping**: Generates a comprehensive map of symlinks (e.g., `pointer` to `left_ptr`) so your theme never "breaks" when hovering over links.
   - **Auto-Installation**: Generates `index.theme` files and safely installs everything to `~/.local/share/icons`.

2. **`set-cursor` (Global Theme Setter)**:
   - **Interactive Picker**: Choose your installed cursor themes easily via an interactive menu using `fzf`.
   - **Global Sync**: Automatically updates Hyprland, GTK2/3/4, and GNOME settings so your cursor is consistent across all apps.

## 🛠️ Installation & Setup

### 1. Converter Dependencies
Requires Python and `win2xcur` for processing Windows themes. (Native Linux themes require no dependencies).

<img src="https://cdn.simpleicons.org/debian/A81D33" width="16" /> Debian / <img src="https://cdn.simpleicons.org/ubuntu/E95420" width="16" /> Ubuntu
```bash
sudo apt update && sudo apt install -y python3 python3-pip fzf
```
<img src="https://cdn.simpleicons.org/fedora/51A2DA" width="16" /> Fedora
```bash
sudo dnf install -y python3 python3-pip fzf
```
<img src="https://cdn.simpleicons.org/archlinux/1793D1" width="16" /> Arch Linux
```bash
sudo pacman -S --noconfirm python python-pip fzf
```

Then install the required Python package:
```bash
pip install win2xcur
```

### 2. Setter Setup
Make the `set-cursor` script executable and move it to your local bin directory (ensure `~/.local/bin` is in your `$PATH`):
```bash
chmod +x set-cursor
cp set-cursor ~/.local/bin/
```

## 🚀 Usage

### Converting & Installing Cursors
You can install a specific theme by passing the folder path, or run the script without arguments to automatically scan and process all folders in the current directory:
```bash
# Install a specific theme
bash convert_cursors.sh /path/to/theme/folder

# Process all folders in the current directory
bash convert_cursors.sh
```

### Setting Cursors Globally
Run the `set-cursor` script to change your cursor theme and size.
```bash
# Interactive picker (requires fzf)
set-cursor

# Set theme manually (prompts for size)
set-cursor <ThemeName>

# List available themes
set-cursor --list

# Uninstall a theme — interactive picker
set-cursor --uninstall

# Uninstall a specific theme directly
set-cursor --uninstall <ThemeName>
```

## 🐛 Troubleshoot
- **`win2xcur not found`**: Ensure that your Python `pip` binary path (usually `~/.local/bin`) is included in your system's `$PATH`.
- **Cursors not applying immediately**: After installation, make sure to restart your compositor, or just use the `set-cursor` script to re-apply the theme. GTK apps might need a restart to reflect the new cursor.

## 📝 Disclaimer & License
This toolkit is provided "as is", without warranty of any kind. I built this tool for personal use, but I am releasing it as open-source under the **MIT License**. 

You are completely free to use, modify, and distribute it. See the [LICENSE](LICENSE) file for more details.
