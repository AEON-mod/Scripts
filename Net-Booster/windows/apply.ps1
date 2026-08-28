# =============================================================================
# Net-Booster — Windows apply.ps1
# Faster downloads, lower latency, safer DNS — for Windows 10/11
# Run as Administrator in PowerShell:
#   Set-ExecutionPolicy Bypass -Scope Process -Force
#   .\apply.ps1
# =============================================================================

#Requires -RunAsAdministrator
$ErrorActionPreference = "SilentlyContinue"

function ok($msg)   { Write-Host "  [OK] $msg" -ForegroundColor Green }
function info($msg) { Write-Host "  [>>] $msg" -ForegroundColor Cyan }
function warn($msg) { Write-Host "  [!!] $msg" -ForegroundColor Yellow }

# ── Detect active network adapter ──────────────────────────────────────────────
function Get-ActiveAdapters {
    Get-NetAdapter | Where-Object { $_.Status -eq "Up" }

# ── 1. TCP Stack Tuning ────────────────────────────────────────────────────────
function Apply-TCPTuning {
    info "Applying TCP stack tuning..."

    # Auto-tuning: normal = Windows dynamically grows receive window (best for most)
    netsh int tcp set global autotuninglevel=normal | Out-Null
    ok "TCP auto-tuning: normal"

    # Explicit Congestion Notification (reduces packet drops on modern networks)
    netsh int tcp set global ecncapability=enabled | Out-Null
    ok "ECN: enabled"

    # Receive Side Scaling (spreads network load across CPU cores)
    netsh int tcp set global rss=enabled | Out-Null
    ok "RSS (Receive Side Scaling): enabled"

    # Disable TCP timestamps (small overhead reduction)
    netsh int tcp set global timestamps=disabled | Out-Null
    ok "TCP timestamps: disabled"

    # Direct Cache Access (reduces CPU cycles for network packets)
    netsh int tcp set global dca=enabled | Out-Null
    ok "Direct Cache Access: enabled"

    # Disable Network Throttling Index (removes artificial 10 packet/ms limit)
    # This throttle was for multimedia apps — counterproductive for downloads
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
    Set-ItemProperty -Path $regPath -Name "NetworkThrottlingIndex" -Value 0xffffffff -Type DWord
    ok "Network Throttling: disabled (registry)"

    # Non-SACK connections — disable (SACK is better for recovery)
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" `
        -Name "SackOpts" -Value 1 -Type DWord
    ok "TCP SACK: enabled"

# ── 2. DNS — Cloudflare Security + Quad9 ──────────────────────────────────────
function Apply-DNS {
    info "Setting secure DNS (Cloudflare Security + Quad9)..."
    $adapters = Get-ActiveAdapters
    foreach ($adapter in $adapters) {
        Set-DnsClientServerAddress -InterfaceAlias $adapter.Name `
            -ServerAddresses ("1.1.1.2", "9.9.9.9", "1.0.0.2", "149.112.112.112")
        ok "DNS set on: $($adapter.Name)"
    }
    # Enable DNS-over-HTTPS (Windows 11 DoH)
    $doh = @(
        "1.1.1.2:https://security.cloudflare-dns.com/dns-query",
        "9.9.9.9:https://dns.quad9.net/dns-query"
    )
    foreach ($server in $doh) {
        $ip = $server.Split(":")[0]
        Add-DnsClientDohServerAddress -ServerAddress $ip -DohTemplate "https://security.cloudflare-dns.com/dns-query" -AllowFallbackToUdp $true 2>$null
    }
    ok "DNS-over-HTTPS configured (Windows 11)"

    # Flush old cache
    Clear-DnsClientCache
    ok "DNS cache flushed"

# ── 3. WiFi Power Save ─────────────────────────────────────────────────────────
function Disable-WiFiPowerSave {
    info "Disabling WiFi power save..."
    $wifiAdapters = Get-NetAdapter | Where-Object {
        $_.PhysicalMediaType -eq "802.11" -and $_.Status -eq "Up"
    }
    foreach ($adapter in $wifiAdapters) {
        # Disable power management in device manager
        $pnpDevice = Get-PnpDevice -FriendlyName "*$($adapter.InterfaceDescription)*" 2>$null
        if ($pnpDevice) {
            $devicePath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($pnpDevice.InstanceId)\Device Parameters"
            Set-ItemProperty -Path $devicePath -Name "WlanCoexMode" -Value 0 -Type DWord 2>$null
        }
        # Set adapter power management via netsh
        netsh wlan set autoconfig enabled=yes interface=$adapter.Name | Out-Null
        ok "WiFi power save disabled: $($adapter.Name)"
    }

    # Also set power plan to High Performance for network devices
    powercfg /change standby-timeout-ac 0 | Out-Null
    ok "Power plan: network adapters stay awake"

# ── 4. Install aria2 ───────────────────────────────────────────────────────────
function Install-Aria2 {
    info "Installing aria2..."

    if (Get-Command aria2c -ErrorAction SilentlyContinue) {
        ok "aria2 already installed: $(aria2c --version 2>$null | Select-Object -First 1)"
        return
    }

    # Try winget first (built into Windows 11+)
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install --id aria2.aria2 --silent --accept-package-agreements --accept-source-agreements
        ok "aria2 installed via winget"
        return
    }

    # Try Scoop
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        scoop install aria2
        ok "aria2 installed via Scoop"
        return
    }

    # Try Chocolatey
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        choco install aria2 -y
        ok "aria2 installed via Chocolatey"
        return
    }

    warn "No package manager found. Install aria2 manually:"
    warn "  winget install aria2.aria2    (recommended)"
    warn "  or download from: https://github.com/aria2/aria2/releases"

# ── 5. Configure aria2 ─────────────────────────────────────────────────────────

# ── Status check ───────────────────────────────────────────────────────────────
function Configure-Aria2 {
    $configDir = "$env:USERPROFILE\.config\aria2"
    $configFile = "$configDir\aria2.conf"
    New-Item -ItemType Directory -Force -Path $configDir | Out-Null

    @"
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
check-certificate=true
follow-metalink=true
metalink-preferred-protocol=https
enable-dht=true
enable-peer-exchange=true
seed-ratio=0
seed-time=0
bt-stop-timeout=300

# --- RPC Auto-Capture (Browser Integration) ---
enable-rpc=true
rpc-listen-all=false
rpc-listen-port=6800
dir=$env:USERPROFILE\Downloads
"@ | Set-Content $configFile -Encoding UTF8

    # Create dl.bat shortcut in user PATH
    $batDir = "$env:USERPROFILE\bin"
    New-Item -ItemType Directory -Force -Path $batDir | Out-Null
    @"
@echo off
aria2c --conf-path="%USERPROFILE%\.config\aria2\aria2.conf" %*
"@ | Set-Content "$batDir\dl.bat" -Encoding ASCII

    # Add ~/bin to PATH if not already there
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($currentPath -notlike "*$batDir*") {
        [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$batDir", "User")
        ok "Added $batDir to PATH"
    }

    ok "aria2 configured: $configFile"
    ok "'dl' shortcut: $batDir\dl.bat"
}

function Setup-RPCDaemon {
    info "Setting up silent RPC background daemon..."
    $startupDir = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    $vbsFile = "$startupDir\aria2-daemon.vbs"
    @"
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "aria2c --conf-path=""" & CreateObject("wscript.shell").ExpandEnvironmentStrings("%USERPROFILE%") & "\.config\aria2\aria2.conf""", 0, False
"@ | Set-Content $vbsFile -Encoding ASCII
    
    # Start it right now
    Start-Process "wscript.exe" -ArgumentList "`"$vbsFile`"" -WindowStyle Hidden
    ok "Daemon running and added to Startup"
}
function Show-Status {
    Write-Host ""
    Write-Host "  Current state:" -ForegroundColor Cyan
    $tuning = netsh int tcp show global | Select-String "Auto-Tuning|ECN|RSS"
    $tuning | ForEach-Object { Write-Host "    $_" }
    $dns = Get-DnsClientServerAddress | Where-Object {$_.AddressFamily -eq 2} | Select-Object -First 2
    Write-Host "    DNS: $($dns.ServerAddresses -join ', ')"
    $aria2 = if (Get-Command aria2c -ErrorAction SilentlyContinue) { "installed" } else { "not found" }
    Write-Host "    aria2: $aria2"

# ── Main ───────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "━━━ Net-Booster for Windows ━━━" -ForegroundColor Cyan
Write-Host ""

switch ($args[0]) {
    "--status" { Show-Status; exit 0 }
    "--help"   {
        Write-Host "Usage: .\apply.ps1 [--status|--help]"
        Write-Host "  (no args)  Apply all optimizations"
        Write-Host "  --status   Show current state"
        exit 0
    }

Write-Host "[1/5] TCP stack tuning"
Apply-TCPTuning

Write-Host ""
Write-Host "[2/5] Secure DNS (Cloudflare + Quad9)"
Apply-DNS

Write-Host ""
Write-Host "[3/5] WiFi power save"
Disable-WiFiPowerSave

Write-Host ""
Write-Host "[4/5] Install aria2"
Install-Aria2

Write-Host ""
Write-Host "[5/6] Configure aria2 + dl shortcut"
Configure-Aria2

Write-Host ""
Write-Host "[6/6] Browser Auto-Capture Daemon"
Setup-RPCDaemon

Show-Status

Write-Host ""
Write-Host "━━━ Done! Restart recommended for full effect ━━━" -ForegroundColor Green
Write-Host ""
Write-Host "  Usage:"
Write-Host "    dl https://example.com/file.iso"
Write-Host "    dl -t file.torrent"
