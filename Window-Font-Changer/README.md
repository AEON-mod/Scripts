<div align="center">

# 🎨 PC Font Changer

**Swap your Windows system font in seconds — no tools, no code, just registry.**

[![Windows](https://img.shields.io/badge/Windows-10%20%2F%2011-0078D4?style=flat-square&logo=windows&logoColor=white)](https://www.microsoft.com/windows)
[![License](https://img.shields.io/badge/License-MIT-22c55e?style=flat-square)](LICENSE)

</div>

---

## ⚡ Quick Start

> **Before you begin** — create a restore point: `Win+R` → `sysdm.cpl` → *System Protection* → *Create*

**1 · Install your font**
Download a `.ttf` / `.otf` → right-click → **Install**

**2 · Set your font**
Open `Font changer.reg` in Notepad → replace `YOUR_FONT_NAME_HERE` with your font's **exact name** → save → double-click → *Yes* twice → **restart**

**3 · Revert anytime**
Double-click `Font Changer to Default.reg` → *Yes* twice → **restart**

---

## 🔍 Finding the Exact Font Name

```
Win + R  →  control fonts  →  copy the name exactly as shown
```

> Case-sensitive! `Roboto` ✅ · `roboto` ❌ · `ROBOTO` ❌

---

## 🛠 Troubleshooting

| Problem | Fix |
|---|---|
| Font not applying | Double-check spelling in Fonts control panel |
| Registry blocked | Right-click `.reg` → **Run as Administrator** |
| No change after restart | `taskkill /f /im explorer.exe` then `start explorer.exe` |
| System feels off | Run `Font Changer to Default.reg` immediately |

**View all installed fonts via PowerShell:**
```powershell
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" |
  Select-Object -ExpandProperty Property | Sort-Object
```

---

## ⚠️ Disclaimer

Registry edits can affect system stability. Always back up first. Use at your own risk.

Tested on **Windows 10 22H2** · **Windows 11 23H2**

---

<div align="center">

Made with ❤️ by **AEON-mod** · [Issues](../../issues) · [PRs](../../pulls)

</div>
