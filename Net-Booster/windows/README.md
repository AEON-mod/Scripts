<div align="center">

# 🪟 Net-Booster for Windows
**Essential Windows network tuning — faster downloads, lower latency, better security.**

</div>

---

## 🚀 Installation

Install the required parallel download manager in a single command matching your package manager, then run the optimization script.

### Winget (Windows 11 Default)
```powershell
winget install aria2.aria2 --silent --accept-package-agreements --accept-source-agreements
```

### Scoop
```powershell
scoop install aria2
```

### Chocolatey
```powershell
choco install aria2 -y
```

---

## ⚡ Quick Start (Recommended)

After installing `aria2`, open **PowerShell as Administrator** and apply all system network optimizations:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\apply.ps1
```

To verify current state without making changes:
```powershell
.\apply.ps1 --status
```

---

## 📦 What It Does

| Optimization | Effect |
| :--- | :--- |
| 🚀 **TCP auto-tuning: normal** | Windows dynamically grows buffers for fast connections |
| ⚡ **TCP ECN / RSS enabled** | Reduces packet drops and uses all CPU cores for network |
| 🚦 **Network Throttling OFF** | Removes artificial 10 packet/ms limit (registry fix) |
| 🔋 **WiFi power save OFF** | Removes latency spikes during downloads |
| 📥 **`aria2` configured** | 16-connection parallel downloader |
| 🛠️ **`dl` command** | One-command fast download shortcut |

---

## 🔧 Manual Steps (if you prefer)

### 1. TCP & Network Tuning
Open PowerShell as Admin:
```powershell
netsh int tcp set global autotuninglevel=normal
netsh int tcp set global ecncapability=enabled
netsh int tcp set global rss=enabled
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xffffffff -Type DWord
```

### 2. Disable WiFi Power Save
```powershell
netsh wlan set autoconfig enabled=yes interface="Wi-Fi"
powercfg /change standby-timeout-ac 0
```

### 3. Configure aria2
Create `%USERPROFILE%\.config\aria2\aria2.conf`:
```ini
split=16
max-connection-per-server=16
min-split-size=1M
max-concurrent-downloads=5
max-download-limit=0
continue=true
check-certificate=true
```

Create a batch file `dl.bat` in a folder in your PATH:
```cmd
@echo off
aria2c --conf-path="%USERPROFILE%\.config\aria2\aria2.conf" %*
```

### 4. Secure DNS (Cloudflare Security)
```powershell
Set-DnsClientServerAddress -InterfaceAlias "Wi-Fi" -ServerAddresses ("1.1.1.2", "9.9.9.9")
Clear-DnsClientCache
```

---

## 💡 Usage After Install

```powershell
# Download a file (16 parallel connections, auto-resume)
dl https://example.com/largefile.iso

# Multiple files at once
dl https://url1.com/file1 https://url2.com/file2

# Torrent
dl -t file.torrent
```

### 🌐 Browser Auto-Integration (Optional)

The optimization script automatically sets up a background listener. To send all your browser downloads through the Net-Booster engine automatically:

1. Install the extension for your browser:
   * **Chrome / Edge / Brave:** [Aria2 for Chrome](https://chrome.google.com/webstore/detail/aria2-for-chrome/mpkodccbngfoacfalldjimigbofkhgjn)
   * **Firefox:** [Aria2 Integration](https://addons.mozilla.org/en-US/firefox/addon/aria2-integration/)
2. **Right-click** the extension icon in your toolbar and select **Options / Settings**.
3. Click the **`+` (Add)** button to create a connection profile:
   * **Name:** Net-Booster
   * **Host:** `localhost`
   * **Port:** `6800`
   * **Secret:** *(Leave completely blank)*
4. **CRITICAL SPEED FIX:** Scroll down to the **RPC Parameters** box. By default, it says `split: 5`. **You must delete this text so the box is empty!** (Otherwise, it will bottleneck the 16-connection setup down to 5).
5. Click **Save** and turn on **"Auto-Capture"**.
