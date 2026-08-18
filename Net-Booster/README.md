<div align="center">

# 🚀 Net-Booster
**Cross-Platform Network Speed & Latency Optimizer**

[![Linux](https://img.shields.io/badge/OS-Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)]()
[![Windows](https://img.shields.io/badge/OS-Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)]()
[![macOS](https://img.shields.io/badge/OS-macOS-000000?style=for-the-badge&logo=apple&logoColor=white)]()

A toolkit to permanently boost network throughput, reduce latency, and increase DNS security. It achieves this by bypassing legacy OS throttling, expanding TCP buffers, disabling power-saving latency spikes, and leveraging a 16-connection parallel download manager.

---
</div>

## 💻 Choose Your OS

| Platform | Quick Link | Install Command |
| :--- | :--- | :--- |
| 🐧 **Linux** | [Linux Setup Guide](linux/README.md) | `cd linux && sudo bash apply.sh` |
| 🪟 **Windows** | [Windows Setup Guide](windows/README.md) | `cd windows && .\apply.ps1` |
| 🍎 **macOS** | [macOS Setup Guide](macos/README.md) | `cd macos && sudo bash apply.sh` |

---


## ⚡ The `dl` Command

After running the script for your OS, the `dl` command becomes available everywhere in your terminal. It replaces `wget` or `curl` for heavy lifting.

```bash
# Download a single file (splits into 16 parallel streams)
dl https://example.com/massive-file.iso

# Download multiple files at once
dl https://site.com/file1 https://site.com/file2

# Download a torrent
dl -t ubuntu.torrent

# Download using metalink (automatically finds the fastest mirrors)
dl -m file.metalink
```

> **Note:** If a download is interrupted, just run the exact same `dl` command again — it will automatically resume exactly where it left off without re-downloading existing chunks.

---

## 🧠 Detailed Working Explanation

Here is exactly what happens under the hood to maximize your network performance on each platform:

### 🐧 Linux
*   **TCP Stack Uncapping:** Default OS buffers are tuned for legacy networks. We expand them to 64MB (`rmem_max`, `wmem_max`) to ensure gigabit connections don't drop packets.
*   **Congestion Control:** Activates `BBR` and the `FQ` (Fair Queueing) packet scheduler, which are vastly superior to legacy CUBIC for high-speed, lossy networks.
*   **Latency Reduction:** Enables TCP Fast Open (`tcp_fastopen=3`), saving 1 full RTT on repeat connections.
*   **Power Management:** Disables WiFi power-save features via a persistent `udev` rule that prevents the radio from sleeping, eliminating random ping spikes during gaming.

### 🪟 Windows
*   **TCP Auto-Tuning:** Sets global auto-tuning to `normal`, allowing Windows to dynamically grow receive windows for fast connections. 
*   **Hardware Acceleration:** Enables `RSS` (Receive Side Scaling) to spread network processing across multiple CPU cores, and `ECN` (Explicit Congestion Notification) to reduce packet retransmission.
*   **Registry Unthrottling:** Disables the legacy `NetworkThrottlingIndex` (which historically capped packets to 10 packets/ms for multimedia prioritization, artificially hurting raw download speed).
*   **Power Management:** Uses `netsh` and registry modifications to disable `WlanCoexMode` power-saving on WiFi adapters.

### 🍎 macOS
*   **BSD TCP Tuning:** Modifies `sysctl` to expand `kern.ipc.maxsockbuf` to 8MB and expands `net.inet.tcp.sendspace` and `recvspace` to 1MB. Disables delayed ACKs (`delayed_ack=0`) for snappier responses.
*   **Power & Throttling (`pmset`):** macOS aggressively puts background apps to sleep. We enable `tcpkeepalive` and `womp` (Wake on Network) so the adapter doesn't drop packets during micro-sleeps. 
*   **App Nap Bypass:** Globally disables App Nap (`NSAppSleepDisabled`) to prevent macOS from pausing your background downloads.

---
<div align="center">
<i>Built for maximum throughput and minimum latency.</i>
</div>
