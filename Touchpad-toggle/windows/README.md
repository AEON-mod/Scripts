<h1 align="center">🪟 TouchpadSwitch — Windows</h1>

<p align="center">
  <img src="https://img.shields.io/badge/Windows_10%2F11-Supported-blue?style=flat-square" alt="Windows">
  <img src="https://img.shields.io/badge/AutoHotkey_v2-Required-orange?style=flat-square" alt="AHK">
  <img src="https://img.shields.io/badge/Shortcut-Win%2BCtrl%2BL-blueviolet?style=flat-square" alt="Shortcut">
</p>

> Requires **Administrator** privileges to toggle hardware devices.

---

## 📋 Prerequisites

1. **AutoHotkey v2** — [Download here](https://www.autohotkey.com/)
2. **Admin rights** — the script uses `Disable-PnpDevice` / `Enable-PnpDevice`

---

## 🚀 Install

### Option A — Automated

```
1. Right-click install.bat → "Run as administrator"
2. Follow prompts (optionally adds to startup)
3. Press Win + Ctrl + L to toggle!
```

### Option B — Manual

```
1. Right-click touchpad-toggle.ahk → "Run as administrator"
2. Script appears in system tray (bottom-right)
3. Press Win + Ctrl + L
```

---

## 🎯 Usage

| Action | How |
|---|---|
| Toggle touchpad | Press `Win + Ctrl + L` |
| Toggle via tray | Right-click tray icon → "Toggle Touchpad" |
| Exit | Right-click tray icon → "Exit" |

A **TrayTip notification** confirms each toggle.

---

## ⚙️ How It Works

```
Win+Ctrl+L pressed
    ↓
AutoHotkey runs PowerShell (hidden)
    ↓
Get-PnpDevice finds touchpad (HID / Mouse class)
    ↓
Disable-PnpDevice  or  Enable-PnpDevice
    ↓
TrayTip notification
```

The script searches for devices matching: `touchpad`, `trackpad`, `precision`, `HID-compliant touch`.

---

## 🔄 Auto-Start on Login

**If you used the installer** — it offers this during setup.

**Manual method:**
1. Press `Win + R` → type `shell:startup` → Enter
2. Create a shortcut to `touchpad-toggle.ahk`
3. Right-click shortcut → Properties → Advanced → ✅ **Run as administrator**

---

## ✅ Verify Touchpad is Detectable

Open **PowerShell as Admin** and run:

```powershell
Get-PnpDevice -Class 'HIDClass' -Status 'OK' |
  Where-Object { $_.FriendlyName -match 'touch|trackpad|precision' } |
  Select-Object FriendlyName, InstanceId, Status
```

If empty, also try:
```powershell
Get-PnpDevice -Class 'Mouse' | Select-Object FriendlyName, Status
```

---

## 🗑️ Uninstall

1. Right-click tray icon → **Exit**
2. Delete the script folder
3. Remove startup shortcut: `Win+R` → `shell:startup` → delete shortcut

---

## 🛠️ Troubleshooting

<details>
<summary><b>"Failed to toggle touchpad"</b></summary>

- Ensure the script is running **as Administrator**
- Some laptop vendors use non-standard device names — check the PowerShell command above and adjust the regex in the script if needed
</details>

<details>
<summary><b>AutoHotkey won't run the script</b></summary>

- Make sure you have **AutoHotkey v2** (not v1)
- Right-click the `.ahk` file → Properties → **Unblock** (if Windows blocked it)
</details>

<details>
<summary><b>Touchpad re-enables after reboot</b></summary>

This is expected — the toggle is session-based. Use the auto-start method above so the script runs on login and tracks state.
</details>

---

## 📁 Files

| File | Purpose |
|---|---|
| `touchpad-toggle.ahk` | Main toggle script (AutoHotkey v2) |
| `install.bat` | Automated installer + startup setup |

---

<p align="center"><a href="../README.md">← Back to main README</a></p>
