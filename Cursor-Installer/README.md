<div align="center">
  <h1>🖱️ Universal Cursor Installer</h1>
  <p><i>A seamless script to install X11 Linux cursors and auto-convert Windows `.ani`/`.cur` themes into native Linux formats.</i></p>
</div>

---

## ⚡ What is it?
Installing cursor themes on Linux—especially those ported from Windows—is usually a tedious, manual process. Windows uses `.ani` (animated) and `.cur` (static) formats, which Linux compositors cannot read directly.

This Universal Installer completely automates the process:
- **Format Conversion**: Detects Windows cursor formats and uses `win2xcur` to cleanly convert them into X11 format without quality loss.
- **Linux Symlink Mapping**: X11 cursor themes require specific file aliases (e.g., pointing `pointer` to `left_ptr`) so that different apps (browsers, Electron, Qt, GTK) recognize the correct cursor. This script generates a comprehensive map of symlinks so your cursor theme never "breaks" or falls back to default when hovering over links or text.
- **Auto-Installation**: Generates the necessary `index.theme` files and safely installs everything to your local `~/.local/share/icons` directory, ready to be applied.
- **Native Support**: Works flawlessly for both native Linux themes (folders with a `cursors/` subdirectory) and raw Windows theme folders.

## 🛠️ Installation & Requirements
Requires Python and `win2xcur` for processing Windows themes. Native Linux themes require no dependencies.
```bash
pip install win2xcur
```

## 🚀 Usage
You can install a specific theme by passing the folder path, or run the script without arguments to automatically scan and process all folders in the current directory:
```bash
# Install a specific theme
bash convert_cursors.sh /path/to/theme/folder

# Process all folders in the current directory
bash convert_cursors.sh
```

## 🐛 Troubleshoot
- **`win2xcur not found`**: Ensure that your Python `pip` binary path (usually `~/.local/bin`) is included in your system's `$PATH`.
- **Cursors not applying**: After installation, make sure to restart your compositor or set the theme explicitly. For example, in Hyprland:
  ```bash
  hyprctl setcursor <ThemeName> 24
  ```

## 📄 License
This project is licensed under the [MIT License](LICENSE).
