<div align="center">
  <h1>🖱️ Universal Cursor Installer</h1>
  <p><i>A seamless script to install X11 Linux cursors and auto-convert Windows `.ani`/`.cur` themes into native Linux formats.</i></p>
</div>

---

## ⚡ What is it?
Installing Windows cursor themes on Linux is usually a hassle. This script magically detects Windows (`.ani`/`.cur`) themes, uses `win2xcur` to convert them to X11, maps aliases correctly, and installs them to `~/.local/share/icons`. It also works flawlessly for native Linux cursor themes!

## 🛠️ Installation & Requirements
Requires Python and `win2xcur` for processing Windows themes. Native Linux themes require no dependencies.
```bash
pip install win2xcur
```

## 🚀 Usage
Install a specific theme by passing the folder path, or run it without arguments to process all themes in the current directory:
```bash
bash convert_cursors.sh /path/to/theme/folder
```

## 🐛 Troubleshoot
- **`win2xcur not found`**: Make sure your `pip` binary path (e.g. `~/.local/bin`) is included in your system's `$PATH`.
- **Cursors not applying**: Ensure you restart your compositor (e.g., Hyprland) or set the theme explicitly using `hyprctl setcursor <ThemeName> 24`.

## 📄 License
This project is licensed under the [MIT License](LICENSE).
