#!/usr/bin/env bash
# =============================================================================
# apply.sh — Apply all network speed optimizations
# Works on: Arch, Debian/Ubuntu, Fedora/RHEL, openSUSE
# =============================================================================
set -e

SYSCTL_FILE="/etc/sysctl.d/99-network-speed.conf"
UDEV_FILE="/etc/udev/rules.d/81-wifi-speed.rules"
REAL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$REAL_USER")
ARIA2_CONF="$USER_HOME/.config/aria2/aria2.conf"
DL_BIN="$USER_HOME/.local/bin/dl"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
ok()   { echo -e "  ${GREEN}✅ $*${NC}"; }
warn() { echo -e "  ${YELLOW}⚠️  $*${NC}"; }
info() { echo -e "  ${BLUE}ℹ️  $*${NC}"; }
err()  { echo -e "  ${RED}❌ $*${NC}"; }

require_root() {
    [[ $EUID -ne 0 ]] && { err "Requires root. Re-running with sudo..."; exec sudo bash "$0" "$@"; }
}

detect_distro() {
    command -v pacman &>/dev/null && echo "arch"   && return
    command -v apt    &>/dev/null && echo "debian" && return
    command -v dnf    &>/dev/null && echo "fedora" && return
    command -v zypper &>/dev/null && echo "opensuse" && return
    echo "unknown"
}

install_aria2() {
    if command -v aria2c &>/dev/null; then
        ok "aria2 already installed ($(aria2c --version 2>/dev/null | head -1))"; return
    fi
    info "Installing aria2..."
    case "$(detect_distro)" in
        arch)     pacman -S --noconfirm aria2 ;;
        debian)   apt-get install -y aria2 ;;
        fedora)   dnf install -y aria2 ;;
        opensuse) zypper install -y aria2 ;;
        *) err "Unknown distro — install aria2 from https://aria2.github.io/"; return 1 ;;
    esac
    ok "aria2 installed"
}

apply_sysctl() {
    cat > "$SYSCTL_FILE" << 'SYSCTL'
# network-speed — TCP kernel tuning (safe on any Linux)
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
SYSCTL
    sysctl --system &>/dev/null
    ok "TCP tuning applied → $SYSCTL_FILE"
}

disable_wifi_powersave() {
    local interfaces=()
    while IFS= read -r iface; do interfaces+=("$iface"); done \
        < <(iw dev 2>/dev/null | awk '/Interface/{print $2}')
    [[ ${#interfaces[@]} -eq 0 ]] && { warn "No WiFi interfaces found"; return; }
    for iface in "${interfaces[@]}"; do
        iw dev "$iface" set power_save off 2>/dev/null && ok "WiFi power_save OFF: $iface"
    done
    {
        echo "# Disable WiFi power save on boot for better throughput"
        for iface in "${interfaces[@]}"; do
            echo "ACTION==\"add\", SUBSYSTEM==\"net\", KERNEL==\"${iface%%[0-9]*}*\", RUN+=\"/usr/sbin/iw dev \$name set power_save off\""
        done
    } > "$UDEV_FILE"
    ok "WiFi udev rule → $UDEV_FILE"
}


configure_aria2() {
    mkdir -p "$(dirname "$ARIA2_CONF")" "$USER_HOME/.local/bin"
    touch "$(dirname "$ARIA2_CONF")/session.gz"
    chown "$REAL_USER" "$(dirname "$ARIA2_CONF")/session.gz"
    
    cat > "$ARIA2_CONF" << ARIA2
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
save-session=$USER_HOME/.config/aria2/session.gz
save-session-interval=30
input-file=$USER_HOME/.config/aria2/session.gz
check-certificate=true
follow-metalink=true
metalink-preferred-protocol=https
enable-dht=true
enable-peer-exchange=true
seed-ratio=0
seed-time=0
bt-stop-timeout=300
bt-save-metadata=true

# --- RPC Auto-Capture (Browser Integration) ---
enable-rpc=true
rpc-listen-all=false
rpc-listen-port=6800
dir=$USER_HOME/Downloads
ARIA2
    
    cat > "$DL_BIN" << DL
#!/bin/bash
# dl — fast parallel downloader (16 connections, auto-resume)
exec aria2c --conf-path="$USER_HOME/.config/aria2/aria2.conf" "\$@"
DL
    chmod +x "$DL_BIN"
    chown -R "$REAL_USER" "$(dirname "$ARIA2_CONF")" "$DL_BIN" 2>/dev/null || true

    ok "aria2 config → $ARIA2_CONF"
    ok "'dl' command → $DL_BIN"
}

setup_rpc_daemon() {
    local SYSTEMD_DIR="$USER_HOME/.config/systemd/user"
    mkdir -p "$SYSTEMD_DIR"
    cat > "$SYSTEMD_DIR/aria2-daemon.service" << SERVICE
[Unit]
Description=Aria2c RPC Daemon
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/aria2c --conf-path=%h/.config/aria2/aria2.conf
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
SERVICE
    chown -R "$REAL_USER" "$USER_HOME/.config/systemd"
    
    sudo -u "$REAL_USER" XDG_RUNTIME_DIR="/run/user/$(id -u "$REAL_USER")" systemctl --user daemon-reload
    sudo -u "$REAL_USER" XDG_RUNTIME_DIR="/run/user/$(id -u "$REAL_USER")" systemctl --user enable --now aria2-daemon.service 2>/dev/null || true
    ok "Background RPC daemon started (Port 6800)"
}
check_status() {
    echo ""
    info "Current state:"
    echo "    TCP congestion:  $(sysctl -n net.ipv4.tcp_congestion_control)"
    echo "    TCP buffer max:  $(( $(sysctl -n net.core.rmem_max) / 1024 / 1024 ))MB"
    echo "    TCP fast open:   $(sysctl -n net.ipv4.tcp_fastopen)"
    echo "    aria2:           $(command -v aria2c &>/dev/null && aria2c --version 2>/dev/null | head -1 || echo 'not installed')"
    echo "    dl shortcut:     $(test -x "$HOME/.local/bin/dl" && echo "✅ ready" || echo "not installed")"
    echo "    sysctl file:     $(test -f "$SYSCTL_FILE" && echo "✅ $SYSCTL_FILE" || echo "not found")"
    echo "    udev rule:       $(test -f "$UDEV_FILE" && echo "✅ $UDEV_FILE" || echo "not found")"
}

main() {
    echo ""
    echo -e "${BLUE}━━━ Network Speed Optimizer ━━━${NC}"
    echo ""
    case "${1:-}" in
        --status|-s) check_status; exit 0 ;;
        --help|-h)
            echo "Usage: sudo bash apply.sh [--status]"
            echo "  (no args)  Apply all optimizations"
            echo "  --status   Show current state without changing anything"
            exit 0
            ;;
    esac
    require_root "$@"
    echo -e "${BLUE}[1/4] aria2 parallel downloader${NC}";  install_aria2
    echo ""; echo -e "${BLUE}[2/4] TCP kernel tuning${NC}";       apply_sysctl
    echo ""; echo -e "${BLUE}[3/4] WiFi power save${NC}";         disable_wifi_powersave
    echo ""; echo -e "${BLUE}[4/5] aria2 config + dl command${NC}"; configure_aria2
    echo ""; echo -e "${BLUE}[5/5] Browser Auto-Capture Daemon${NC}"; setup_rpc_daemon
    check_status
    echo ""
    echo -e "${GREEN}━━━ Done! ━━━${NC}"
    echo "  Usage: dl <url>   dl -t file.torrent   dl <url1> <url2>"
}

main "$@"
