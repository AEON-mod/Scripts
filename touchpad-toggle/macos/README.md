<h1 align="center">🍎 TouchpadSwitch — macOS</h1>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-Monterey%2B-lightgrey?style=flat-square" alt="macOS">
  <img src="https://img.shields.io/badge/Karabiner-Recommended-orange?style=flat-square" alt="Karabiner">
  <img src="https://img.shields.io/badge/Shortcut-⌘%2B⌃%2BL-blueviolet?style=flat-square" alt="Shortcut">
</p>

> [!WARNING]
> **Apple does not provide a public API to fully disable the internal trackpad.**
> This script toggles *"Ignore built-in trackpad when external mouse is present"* — an **external mouse must be connected**.

---

## 📋 Prerequisites

1. An **external USB or Bluetooth mouse** connected
2. [**Karabiner-Elements**](https://karabiner-elements.pqrs.org/) (for the keyboard shortcut)

---

## 🚀 Install

```bash
# 1. Clone the repo
git clone https://github.com/AEON-mod/TouchpadSwitch.git
cd TouchpadSwitch/macos

# 2. Install the script
mkdir -p ~/.local/bin
cp touchpad-toggle.sh ~/.local/bin/touchpad-toggle
chmod +x ~/.local/bin/touchpad-toggle

# 3. Add to PATH (if not already)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# 4. Test it
touchpad-toggle status
```

---

## 🎯 Usage

```bash
touchpad-toggle          # Toggle on/off
touchpad-toggle status   # Check state
touchpad-toggle on       # Force enable
touchpad-toggle off      # Force disable
```

A macOS notification confirms each toggle.

---

## ⌨️ Keyboard Shortcut Setup

### Option A — Karabiner-Elements *(recommended)*

```bash
# Install Karabiner
brew install --cask karabiner-elements

# Copy the rule
mkdir -p ~/.config/karabiner/assets/complex_modifications
cp karabiner-rule.json ~/.config/karabiner/assets/complex_modifications/
```

Then:
1. Open **Karabiner-Elements**
2. Go to **Complex Modifications** → **Add rule**
3. Enable **"Super+Ctrl+L → Toggle Touchpad"**

> `Super` = `⌘ Command` on Mac, so the shortcut is `⌘ + ⌃ + L`

### Option B — Automator Quick Action

1. Open **Automator** → New → **Quick Action**
2. Set *"Workflow receives"* → `no input` in `any application`
3. Add **Run Shell Script** → `~/.local/bin/touchpad-toggle`
4. Save as **"Toggle Trackpad"**
5. System Settings → Keyboard → Shortcuts → Services → assign `⌘⌃L`

---

## ⚙️ How It Works

```
⌘+⌃+L pressed (Karabiner)
    ↓
touchpad-toggle script runs
    ↓
defaults write com.apple.AppleMultitouchTrackpad
  USBMouseStopsTrackpad → 1 (disable) or 0 (enable)
    ↓
macOS notification
```

---

## ⚠️ Known Limitations

| Limitation | Detail |
|---|---|
| External mouse required | macOS only ignores trackpad when another device is connected |
| Logout may be needed | macOS Ventura (13)+ may require logout for changes |
| No hardware disable | Apple provides no API to power off trackpad hardware |

---

## 🗑️ Uninstall

```bash
# Remove script
rm ~/.local/bin/touchpad-toggle

# Reset defaults
defaults delete com.apple.AppleMultitouchTrackpad USBMouseStopsTrackpad
defaults delete com.apple.driver.AppleBluetoothMultitouch.trackpad USBMouseStopsTrackpad

# Remove Karabiner rule
rm ~/.config/karabiner/assets/complex_modifications/karabiner-rule.json
```

---

## 🛠️ Troubleshooting

<details>
<summary><b>Toggle has no effect</b></summary>

- Ensure an **external mouse is connected**
- **Log out and back in** (especially on macOS 13+)
- Check state: `defaults read com.apple.AppleMultitouchTrackpad USBMouseStopsTrackpad`
</details>

<details>
<summary><b>Karabiner shortcut not working</b></summary>

- Verify Karabiner is running (menu bar icon)
- Check Complex Modifications → rule is enabled
- Verify script exists: `ls -la ~/.local/bin/touchpad-toggle`
</details>

---

## 📁 Files

| File | Purpose |
|---|---|
| `touchpad-toggle.sh` | Main toggle script |
| `karabiner-rule.json` | Karabiner-Elements shortcut config |

---

<p align="center"><a href="../README.md">← Back to main README</a></p>
