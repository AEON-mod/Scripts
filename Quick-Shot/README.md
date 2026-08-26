<div align="center">
  <h1>📸 Quick-Shot</h1>
  <p>An aesthetic, hassle-free screenshot wrapper for Hyprland using <b>hyprshot</b> and <b>slurp</b>.</p>
</div>

---

## 📖 About
**Quick-Shot** is a streamlined wrapper around `hyprshot` designed to make capturing screenshots on Hyprland effortless. It elegantly handles saving your screenshots with organized filenames, pushing them to your clipboard, and displaying beautiful notifications. 

Whether you want to capture the whole screen, a specific window, or a custom region, Quick-Shot has you covered!

---

## 🛠️ Dependencies Installation

Before installing Quick-Shot, ensure you have the required dependencies for your Linux distribution. You can install them with a single line:

- **Arch Linux / EndeavourOS:**
  ```bash
  sudo pacman -S jq grim slurp wl-clipboard libnotify
  ```
- **Fedora:**
  ```bash
  sudo dnf install jq grim slurp wl-clipboard libnotify
  ```
- **Ubuntu / Debian:**
  ```bash
  sudo apt install jq grim slurp wl-clipboard libnotify
  ```

---

## 🚀 Installation

You can choose to install Quick-Shot automatically using the provided script, or manually if you prefer having full control over your system.

### Option 1: Automatic Installation (Recommended)
If you don't want to do the manual steps, just run the installation script! It sets up everything for you in seconds.

```bash
git clone https://github.com/AEON-mod/Scripts.git
cd Scripts/Quick-Shot/
bash install.sh
```
*Note: Make sure `~/.local/bin` is in your system's `$PATH`!*

### Option 2: Manual Installation
For those who prefer a hands-on approach:

1. Clone the repository:
   ```bash
   git clone https://github.com/AEON-mod/Scripts.git
   cd Scripts/Quick-Shot/
   ```
2. Create your local bin directory (if it doesn't exist):
   ```bash
   mkdir -p ~/.local/bin
   ```
3. Copy the executables to your local bin:
   ```bash
   cp bin/takeshot ~/.local/bin/
   cp bin/hyprshot ~/.local/bin/
   ```
4. Make them executable:
   ```bash
   chmod +x ~/.local/bin/takeshot ~/.local/bin/hyprshot
   ```

---

## ⚙️ Configuration

### For Standard Hyprland Users (`hyprland.conf`)
Add the following bindings to your `~/.config/hypr/hyprland.conf`. 

> ⚠️ **IMPORTANT**: You must use `bindr` (bind on release) for region and window captures. Using standard `bind` triggers `slurp` while you are still holding down the keys, which causes `slurp` to immediately cancel the selection!

```ini
# Takes a screenshot of the entire output/screen
bindr = Ctrl+Super+Shift, S, exec, takeshot output

# Takes a screenshot of a specific window
bindr = Super+Shift, S, exec, takeshot window

# Takes a screenshot of a selected region
bindr = Super+Ctrl, S, exec, takeshot region
```

### For Caelestia Users (`keybinds.lua`)
If you are using **Caelestia** (which utilizes a Lua-based configuration for Hyprland), you need to pass the `{ release = true }` flag to your `hl.bind` function instead of using `bindr`. Add this to your `~/.config/hypr/hyprland/keybinds.lua`:

```lua
-- Fullscreen screenshot
hl.bind("CTRL + SUPER + SHIFT + S", hl.dsp.exec_cmd("takeshot output"), { release = true })

-- Active window screenshot
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("takeshot window"), { release = true })

-- Region select screenshot
hl.bind("SUPER + CTRL + S", hl.dsp.exec_cmd("takeshot region"), { release = true })
```

---

## 🎨 File Output
Screenshots are automatically saved to `~/Pictures/Screenshots/` (or your default XDG pictures directory) and formatted sequentially based on the current date, ensuring your screenshot folder stays clean and beautiful!
