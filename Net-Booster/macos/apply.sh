#!/usr/bin/env bash
# =============================================================================
# Net-Booster — macOS apply.sh
# Faster downloads, lower latency, safer DNS — for macOS 12+
# Usage: sudo bash apply.sh [--status]
# =============================================================================
set -euo pipefail

GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "  ${GREEN}✅ $*${NC}"; }
info() { echo -e "  ${BLUE}ℹ️  $*${NC}"; }
warn() { echo -e "  ${YELLOW}⚠️  $*${NC}"; }

SYSCTL_CONF="/etc/sysctl.conf"

require_root() {
    [[ $EUID -ne 0 ]] && { echo "Requires sudo. Re-running..."; exec sudo bash "$0" "$@"; }
}

# ── 1. TCP Kernel Tuning ───────────────────────────────────────────────────────
apply_sysctl() {
    # macOS TCP buffer params (BSD-style, different from Linux)
    sysctl -w kern.ipc.maxsockbuf=8388608      # max socket buffer 8MB
    sysctl -w net.inet.tcp.sendspace=1048576   # send buffer 1MB
    sysctl -w net.inet.tcp.recvspace=1048576   # receive buffer 1MB
    sysctl -w net.inet.tcp.win_scale_factor=8  # window scaling
    sysctl -w net.inet.tcp.delayed_ack=0       # disable delayed ACK (faster)
    sysctl -w net.inet.tcp.mssdflt=1440        # optimal MSS for most networks
    sysctl -w net.inet.tcp.keepidle=60000      # keepalive 60s
    sysctl -w net.inet.tcp.keepintvl=10000     # keepalive interval 10s
    sysctl -w net.inet.tcp.keepcnt=6           # keepalive probes
    sysctl -w net.inet.tcp.rfc1323=1           # RFC1323 timestamps+scaling
    sysctl -w net.inet.tcp.fastopen=1          # TCP Fast Open
    ok "TCP kernel tuning applied (immediate)"

    # Persist across reboots via /etc/sysctl.conf
    cat > "$SYSCTL_CONF" << 'SYSCTL'
# Net-Booster — TCP tuning for macOS
kern.ipc.maxsockbuf=8388608
net.inet.tcp.sendspace=1048576
net.inet.tcp.recvspace=1048576
net.inet.tcp.win_scale_factor=8
net.inet.tcp.delayed_ack=0
net.inet.tcp.mssdflt=1440
net.inet.tcp.keepidle=60000
net.inet.tcp.keepintvl=10000
net.inet.tcp.keepcnt=6
net.inet.tcp.rfc1323=1
net.inet.tcp.fastopen=1
SYSCTL
    ok "TCP tuning persisted → $SYSCTL_CONF"
}

# ── 2. DNS — Cloudflare Security + Quad9 ──────────────────────────────────────
apply_dns() {
    # Get all active network services
    local services
    services=$(networksetup -listallnetworkservices 2>/dev/null | tail -n +2 | grep -v "^\*")

    while IFS= read -r svc; do
        local current
        current=$(networksetup -getdnsservers "$svc" 2>/dev/null)
        # Set Cloudflare Security + Quad9
        networksetup -setdnsservers "$svc" 1.1.1.2 9.9.9.9 1.0.0.2 149.112.112.112 2>/dev/null && \
            ok "DNS set on: $svc" || true
    done <<< "$services"

    # Flush DNS cache
    dscacheutil -flushcache
    killall -HUP mDNSResponder 2>/dev/null || true
    ok "DNS cache flushed"

    # Enable DoH via macOS encrypted DNS (macOS 14+)
    info "For DoH on macOS 14+: System Settings → Network → [Interface] → DNS → use 1.1.1.2"
}

# ── 3. WiFi Power Save ─────────────────────────────────────────────────────────
disable_wifi_powersave() {
    # macOS doesn't expose WiFi power management to users directly,
    # but we can ensure the interface stays alive and isn't throttled

    # Disable WiFi power nap (reduces wakeup latency)
    pmset -a womp 1          # Wake on network access
    pmset -a tcpkeepalive 1  # Keep TCP alive during sleep
    ok "WiFi: tcpkeepalive + wake-on-network enabled"

    # Prevent App Nap from throttling network-heavy apps
    defaults write NSGlobalDomain NSAppSleepDisabled -bool YES
    ok "App Nap: disabled for network apps"

    # Ensure network stays active
    local wifi_if
    wifi_if=$(networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2}')
    if [[ -n "$wifi_if" ]]; then
        networksetup -setv6automatic "Wi-Fi" 2>/dev/null || true
        ok "WiFi interface: $wifi_if (power optimizations applied)"
    fi
}

# ── 4. Install aria2 ──────────────────────────────────────────────────────────
install_aria2() {
    if command -v aria2c &>/dev/null; then
        ok "aria2 already installed: $(aria2c --version 2>/dev/null | head -1)"; return
    fi

    if command -v brew &>/dev/null; then
        # Run brew as the original user (not root)
        sudo -u "${SUDO_USER:-$USER}" brew install aria2
        ok "aria2 installed via Homebrew"
    else
        warn "Homebrew not found. Install it first:"
        warn "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        warn "  Then run: brew install aria2"
    fi
}

# ── 5. Configure aria2 + dl shortcut ──────────────────────────────────────────
configure_aria2() {
    local user_home
    user_home=$(eval echo "~${SUDO_USER:-$USER}")
    local config_dir="$user_home/.config/aria2"
    local config_file="$config_dir/aria2.conf"
    local dl_bin="$user_home/.local/bin/dl"

    mkdir -p "$config_dir" "$(dirname "$dl_bin")"

    cat > "$config_file" << 'ARIA2'
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
file-allocation=none
continue=true
check-certificate=true
follow-metalink=true
metalink-preferred-protocol=https
enable-dht=true
enable-peer-exchange=true
seed-ratio=0
seed-time=0
bt-stop-timeout=300
ARIA2

    cat > "$dl_bin" << 'DL'
#!/bin/bash
# dl — fast parallel downloader (16 connections, auto-resume)
exec aria2c --conf-path="$HOME/.config/aria2/aria2.conf" "$@"
DL
    chmod +x "$dl_bin"
    chown -R "${SUDO_USER:-$USER}" "$config_dir" "$dl_bin" 2>/dev/null || true

    # Add ~/.local/bin to PATH in shell configs if not present
    for rc in "$user_home/.zshrc" "$user_home/.bash_profile"; do
        [[ -f "$rc" ]] || continue
        grep -q ".local/bin" "$rc" || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc"
    done

    ok "aria2 configured: $config_file"
    ok "'dl' shortcut: $dl_bin"
}

# ── Status ────────────────────────────────────────────────────────────────────
show_status() {
    echo ""
    info "Current state:"
    echo "    TCP send buffer: $(sysctl -n net.inet.tcp.sendspace 2>/dev/null || echo 'n/a')"
    echo "    TCP recv buffer: $(sysctl -n net.inet.tcp.recvspace 2>/dev/null || echo 'n/a')"
    echo "    Fast Open:       $(sysctl -n net.inet.tcp.fastopen 2>/dev/null || echo 'n/a')"
    echo "    DNS:             $(networksetup -getdnsservers Wi-Fi 2>/dev/null | tr '\n' ' ')"
    echo "    aria2:           $(command -v aria2c &>/dev/null && aria2c --version 2>/dev/null | head -1 || echo 'not installed')"
    echo "    sysctl.conf:     $(test -f "$SYSCTL_CONF" && echo "✅ exists" || echo "not found")"
}

# ── Main ───────────────────────────────────────────────────────────────────────
echo ""
echo "━━━ Net-Booster for macOS ━━━"
echo ""

case "${1:-}" in
    --status|-s) show_status; exit 0 ;;
    --help|-h)
        echo "Usage: sudo bash apply.sh [--status]"
        echo "  (no args)  Apply all optimizations"
        echo "  --status   Show current state"
        exit 0
        ;;
esac

require_root "$@"

echo "[1/5] TCP kernel tuning";           apply_sysctl
echo ""; echo "[2/5] Secure DNS";         apply_dns
echo ""; echo "[3/5] WiFi power config";  disable_wifi_powersave
echo ""; echo "[4/5] Install aria2";      install_aria2
echo ""; echo "[5/5] Configure aria2";    configure_aria2
show_status

echo ""
echo "━━━ Done! ━━━"
echo "  Usage: dl https://example.com/file   |   dl -t file.torrent"
echo "  Note: Reopen terminal for 'dl' command to be available."
