<div align="center">

# 🐧 Net-Booster for Linux
**Essential Linux network tuning — faster downloads, lower latency, better security.**

</div>

---

## 🚀 Installation

Install the required parallel download manager in a single command matching your package manager, then run the optimization script.

### Debian / Ubuntu
```bash
sudo apt update && sudo apt install -y aria2
```

### Fedora
```bash
sudo dnf install -y aria2
```

### Arch Linux
```bash
sudo pacman -S --noconfirm aria2
```

### openSUSE
```bash
sudo zypper install aria2
```

---

## ⚡ Quick Start (Recommended)

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
| 🚀 **TCP buffers → 64MB** | Prevents drops on fast connections |
| ⚡ **TCP Fast Open** | Saves ~50ms per repeat connection |
| 🚦 **BBR + FQ** | Better throughput on modern networks |
| 🔋 **WiFi power save OFF** | Removes latency spikes during downloads |
| 📥 **`aria2` configured** | 16-connection parallel downloader |
| 🛠️ **`dl` command** | One-command fast download shortcut |

---

## 🔧 Manual Steps (if you prefer)

### 1. TCP Kernel Tuning
Create `/etc/sysctl.d/99-network-speed.conf`:
```ini
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.rmem_default = 1048576
net.core.wmem_default = 1048576
net.ipv4.tcp_rmem = 4096 1048576 67108864
net.ipv4.tcp_wmem = 4096 1048576 67108864
net.core.netdev_max_backlog = 16384
net.core.somaxconn = 8192
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq
net.ipv4.tcp_keepalive_time = 60
net.ipv4.tcp_keepalive_intvl = 10
net.ipv4.tcp_keepalive_probes = 6
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_tw_reuse = 1
```
Apply immediately (no reboot needed):
```bash
sudo sysctl --system
```

### 2. Disable WiFi Power Save
```bash
# Find your WiFi interface
iw dev | grep Interface

# Disable power save (replace wlp0s20f3 with your interface)
sudo iw dev wlp0s20f3 set power_save off

# Make it persist across reboots — create /etc/udev/rules.d/81-wifi-speed.rules:
echo 'ACTION=="add", SUBSYSTEM=="net", KERNEL=="wlp*", RUN+="/usr/sbin/iw dev $name set power_save off"' | sudo tee /etc/udev/rules.d/81-wifi-speed.rules
```

### 3. Configure aria2
Create `~/.config/aria2/aria2.conf`:
```ini
split=16
max-connection-per-server=16
min-split-size=1M
max-concurrent-downloads=5
max-download-limit=0
max-upload-limit=512K
max-tries=5
retry-wait=3
timeout=60
connect-timeout=10
file-allocation=falloc
continue=true
save-session=/home/$USER/.config/aria2/session.gz
save-session-interval=30
input-file=/home/$USER/.config/aria2/session.gz
check-certificate=true
```

Create `~/.local/bin/dl`:
```bash
#!/bin/bash
exec aria2c --conf-path="$HOME/.config/aria2/aria2.conf" "$@"
```
```bash
chmod +x ~/.local/bin/dl
```

### 4. DNS Security (optional but recommended)
Use **Cloudflare Security** (blocks malware/phishing) + **Quad9** over TLS.

Edit `/etc/systemd/resolved.conf`:
```ini
[Resolve]
DNS=1.1.1.2#security.cloudflare-dns.com 9.9.9.9#dns.quad9.net
FallbackDNS=1.0.0.2#security.cloudflare-dns.com 149.112.112.112#dns.quad9.net
DNSOverTLS=yes
DNSSEC=allow-downgrade
```
```bash
sudo systemctl restart systemd-resolved
```

---

## 💡 Usage After Install

```bash
# Download a file (16 parallel connections, auto-resume on crash)
dl https://example.com/largefile.iso

# Multiple files at once
dl https://url1.com/file1 https://url2.com/file2

# Torrent
dl -t file.torrent

# Metalink (picks best mirrors automatically)
dl -m file.metalink

# Check everything is working
bash apply.sh --status
```
