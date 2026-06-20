# 🎨 PC Font Changer

<div align="center">

**Quickly change your Windows PC fonts using simple registry tweak files**

![Windows 10](https://img.shields.io/badge/Windows-10+-0078D4?style=flat-square&logo=windows)
![Windows 11](https://img.shields.io/badge/Windows-11+-0078D4?style=flat-square&logo=windows)
![MIT License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

*No coding needed • No technical knowledge required • One-click execution*

</div>

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🎨 **Custom Fonts** | Change to any installed font on your PC |
| 🚀 **One-Click Easy** | Download, edit, and run - that's it! |
| ↩️ **Easy Revert** | Restore default fonts instantly with one click |
| 🪟 **Windows 10/11** | Tested and working on latest Windows versions |
| 📝 **Simple Edit** | Only need to type your font name |

---

## 🚀 Quick Start

### Step 1️⃣: Install Your Font

1. Download your desired font file (`.ttf` or `.otf`)
2. Right-click → **Install** (or double-click → **Install** button)
3. Verify the font appears in **Control Panel > Fonts**

### Step 2️⃣: Change to Custom Font

1. Open **font-changer.reg** with Notepad
2. Find and edit this line:
   ```
   YOUR_FONT_NAME_HERE
   ```
3. Replace with your **EXACT font name** (case-sensitive!)
   - ✅ Correct: `Segoe UI`, `Arial`, `Roboto`
   - ❌ Wrong: `segoe ui`, `ARIAL`, `roboto light`

4. Save the file
5. Double-click the `.reg` file → Click **Yes** twice
6. **Restart your PC** (critical!)

### Step 3️⃣: Revert to Default Fonts

1. Double-click **font-changer-to-default.reg**
2. Click **Yes** twice
3. **Restart your PC**

---

## 🔍 How to Find Your Font's Exact Name

1. Press `Win + R` → Type `control fonts` → Press Enter
2. Find your installed font in the list
3. Copy the **exact name** (including spaces and capitalization)
4. Paste it into the `font-changer.reg` file

> **Pro Tip:** Font names are **case-sensitive**! Double-check capitalization.

---

## 📁 File Structure

```
Font Change Commands/
├── font-changer.reg              # ➡️ EDIT THIS FILE
├── font-changer-to-default.reg   # ➡️ Use to revert
├── example-fonts/
│   ├── Roboto.ttf                # Sample fonts (optional)
│   └── OpenSans.ttf
├── screenshots/
│   ├── how-to-edit.png
│   └── fonts-control-panel.png
└── README.md
```

---

## ⚠️ Important Rules

| Do ✅ | Don't ❌ |
|------|--------|
| Edit `font-changer.reg` | Edit `font-changer-to-default.reg` |
| Use exact font name spelling | Change capitalization |
| Create a restore point first | Skip the restart |
| Run as Administrator if blocked | Force restart mid-process |

---

## 🔧 Troubleshooting

| Problem | Solution |
|---------|----------|
| Font name not working | Check exact spelling in Windows Fonts control panel |
| "Registry edit blocked" error | Right-click `.reg` → **Run as Administrator** |
| No visual changes after restart | Restart `explorer.exe` or do a full PC reboot |
| System feels unstable | Run `font-changer-to-default.reg` immediately |
| Permission denied | Create a system restore point first |

### Quick Fix Script

If changes don't apply after restart, open **Command Prompt as Administrator** and run:

```cmd
taskkill /f /im explorer.exe
start explorer.exe
```

---

## 💡 Examples

### Example 1: Using "Roboto"
Edit `font-changer.reg` and change:
```
YOUR_FONT_NAME_HERE
```
To:
```
Roboto
```

### Example 2: Using "Segoe UI SemiLight"
```
Segoe UI SemiLight
```
*(Notice the space and capital L - must be exact!)*

---

## 🛡️ Safety Recommendations

### Create a Restore Point
1. Press `Win + R` → Type `sysdm.cpl` → Press Enter
2. Click **System Protection** → **Create**
3. Give it a name and confirm

### Backup Your Registry
1. Press `Win + R` → Type `regedit` → Press Enter
2. Click **File** → **Export** → Save to a safe location

### Test First (Optional but Recommended)
- Test these changes on a virtual machine before applying to your main PC

---

## 🎯 Command Reference

### PowerShell: View All Installed Fonts
```powershell
Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" | 
  Select-Object -ExpandProperty Property | 
  Sort-Object
```

---

## 📸 Screenshots

- **Editing font-changer.reg with Notepad**
- **Registry prompt when running .reg file**
- **Finding exact font name in Windows Fonts settings**

---

## 📜 Disclaimer

⚠️ **Use at your own risk!** 

Modifying the Windows registry can affect system stability. I am not responsible for any system issues that may occur. **Always create a backup before proceeding.**

Tested on:
- Windows 10 (22H2)
- Windows 11 (23H2)

---

## 🤝 Contributing

Found a bug or want to suggest improvements? 
- [Open an issue](../../issues)
- [Submit a pull request](../../pulls)

---

## 📄 License

MIT License - Free to use, modify, and distribute

---

<div align="center">

Made with ❤️ by **AEON-mod**

**⭐ Star this repo if it helped you!**

</div>
