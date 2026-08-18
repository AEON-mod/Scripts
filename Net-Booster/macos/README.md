<div align="center">

# 🍎 Net-Booster for macOS
**Essential macOS network tuning — faster downloads, lower latency, better security.**

</div>

---

## 🚀 Installation

Install the required parallel download manager in a single command, then run the optimization script.

### Homebrew
```bash
brew install aria2
```
> *If you don't have Homebrew, install it via: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`*

---

## ⚡ Quick Start (Recommended)

After installing `aria2`, apply all system network optimizations automatically:

```bash
# Clone or navigate to this folder, then:
sudo bash apply.sh
```

To verify current state without making changes:
```bash
bash apply.sh --status
```

---

## 📦 What It Does

| Optimization | Effect |
| :--- | :--- |
| 🚀 **TCP buffers → 8MB / 1MB** | Prevents drops on fast connections (`sysctl` tuning) |
| ⚡ **TCP Fast Open / No Delayed ACK**| Saves ~50ms per repeat connection |
| 🔋 **WiFi tcpkeepalive / womp ON** | Keeps adapter awake, preventing latency spikes (`pmset`) |
| 🚦 **App Nap Disabled** | Prevents macOS from throttling background downloads |
| 📥 **`aria2` configured** | 16-connection parallel downloader |
| 🛠️ **`dl` command** | One-command fast download shortcut |

---

## 🔧 Manual Steps (if you prefer)

### 1. TCP Kernel Tuning
```bash
sudo sysctl -w kern.ipc.maxsockbuf=8388608
sudo sysctl -w net.inet.tcp.sendspace=1048576
sudo sysctl -w net.inet.tcp.recvspace=1048576
sudo sysctl -w net.inet.tcp.delayed_ack=0
sudo sysctl -w net.inet.tcp.fastopen=1
```
*(To persist these, add them to `/etc/sysctl.conf`)*

### 2. Disable WiFi Power Throttling
```bash
sudo pmset -a womp 1
sudo pmset -a tcpkeepalive 1
defaults write NSGlobalDomain NSAppSleepDisabled -bool YES
```

### 3. Configure aria2
Create `~/.config/aria2/aria2.conf`:
```ini
split=16
max-connection-per-server=16
min-split-size=1M
max-concurrent-downloads=5
max-download-limit=0
continue=true
check-certificate=true
```

Create an executable script `dl` in `~/.local/bin`:
```bash
#!/bin/bash
exec aria2c --conf-path="$HOME/.config/aria2/aria2.conf" "$@"
```
`chmod +x ~/.local/bin/dl`

### 4. Secure DNS (Cloudflare Security)
```bash
sudo networksetup -setdnsservers Wi-Fi 1.1.1.2 9.9.9.9 1.0.0.2 149.112.112.112
sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
```

---

## 💡 Usage After Install

```bash
# Download a file (16 parallel connections, auto-resume)
dl https://example.com/largefile.iso

# Multiple files at once
dl https://url1.com/file1 https://url2.com/file2

# Torrent
dl -t file.torrent
```

### 🌐 Browser Auto-Integration (Optional)

The optimization script automatically sets up a background listener on your PC. To send all your browser downloads through the 16-connection Net-Booster engine automatically:

1. Install the extension for your browser:
   * **Chrome / Edge / Brave:** [Aria2 for Chrome](https://chrome.google.com/webstore/detail/aria2-for-chrome/mpkodccbngfoacfalldjimigbofkhgjn)
   * **Firefox:** [Aria2 Integration](https://addons.mozilla.org/en-US/firefox/addon/aria2-integration/)
2. **Right-click** the extension icon in your browser toolbar and select **Options** (or Settings).
3. Under **Download Capture**:
   * Turn ON **"Enable auto capture when download file size"**
   * Change the size from `100` MB to `0` MB (so it captures everything).
4. Under **Aria2-RPC-Server**:
   * Verify the URL is exactly `http://localhost:6800/jsonrpc`
   * Leave the Secret Key blank.

**🎉 Done!** Every file you click to download will now instantly route through Net-Booster at maximum speed. Click the extension icon and open **AriaNG** to view your live download dashboard!
