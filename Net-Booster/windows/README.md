<div align="center">

# 🪟 Net-Booster for Windows
**Essential Windows network tuning — faster downloads, lower latency, better security.**

</div>

---

## ⚡ Quick Start (Recommended)

1. Open **PowerShell as Administrator**.
2. Run the following:

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

### 1. Install aria2

Run `winget install aria2.aria2` (or use Scoop/Chocolatey).

### 2. TCP & Network Tuning
Open PowerShell as Admin:
```powershell
netsh int tcp set global autotuninglevel=normal
netsh int tcp set global ecncapability=enabled
netsh int tcp set global rss=enabled
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xffffffff -Type DWord
```

### 3. Disable WiFi Power Save
```powershell
netsh wlan set autoconfig enabled=yes interface="Wi-Fi"
powercfg /change standby-timeout-ac 0
```

### 4. Configure aria2
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

### 5. Secure DNS (Cloudflare Security)
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
