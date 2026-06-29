#!/bin/bash
# Power Mode Manager for ARKUS (i7-12650HX + RTX 4050 Laptop)
# Usage: sudo bash ~/.scripts/game-mode.sh [on|off|wallpaper]
#
# Constraint layout (intel-rapl:0):
#   constraint_0 = long_term  (PL1 - sustained TDP, hardware max = 55W)
#   constraint_1 = short_term (PL2 - burst limit, no enforced hw max)
#   constraint_2 = peak_power (instantaneous cap)
#
# Modes:
#   on        → Gaming: PL1=55W PL2=65W, EPP=performance, turbo ON, max fans
#   off       → Balanced: PL1=45W PL2=55W, EPP=balance_performance, turbo ON
#   wallpaper → Live wallpaper: PL1=35W PL2=45W, EPP=balance_power (cool & quiet)

if [ "$EUID" -ne 0 ]; then
    echo "Run as root: sudo bash $0 $1"
    exit 1
fi

set_power_limits() {
    local pl1_uw=$1  # long_term / sustained
    local pl2_uw=$2  # short_term / burst
    # Clamp PL1 to hardware max (55W = 55000000 uw)
    local hw_max
    hw_max=$(cat /sys/class/powercap/intel-rapl:0/constraint_0_max_power_uw 2>/dev/null || echo 55000000)
    if [ "$pl1_uw" -gt "$hw_max" ]; then
        echo "  ⚠ PL1 clamped to hw max: ${hw_max}uw"
        pl1_uw=$hw_max
    fi
    echo "$pl1_uw" > /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw 2>/dev/null || true
    echo "$pl2_uw" > /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw 2>/dev/null || true
    echo "  ✅ PL1(long_term)=$(( pl1_uw / 1000000 ))W  PL2(short_term)=$(( pl2_uw / 1000000 ))W"
}

set_epp() {
    local pref=$1
    for epp in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
        echo "$pref" > "$epp" 2>/dev/null || true
    done
    echo "  ✅ EPP: $pref"
}

case "${1:-}" in
    on)
        echo "🎮 GAMING MODE: ON"
        echo ""

        # Max performance power limits (PL1 clamped to hw max 55W)
        set_power_limits 55000000 65000000

        # Performance EPP
        set_epp performance

        # Ensure turbo is on
        echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
        echo "  ✅ Turbo boost: ON"

        # Set NVIDIA to prefer maximum performance
        nvidia-settings -a "[gpu:0]/GPUPowerMizerMode=1" 2>/dev/null || true
        echo "  ✅ GPU: Prefer Maximum Performance"

        # Max fan speed
        legion_cli maximumfanspeed-enable 2>/dev/null || true
        echo "  ✅ Fans: Maximum speed"

        # Stop non-essential services
        systemctl stop cups 2>/dev/null || true
        systemctl stop avahi-daemon 2>/dev/null || true
        echo "  ✅ Stopped: CUPS, Avahi"

        echo ""
        echo "🎮 Gaming mode active! Run 'sudo bash ~/.scripts/game-mode.sh off' when done."
        ;;

    off)
        echo "💻 BALANCED MODE: ON"
        echo ""

        # Balanced power limits
        set_power_limits 45000000 55000000

        # Balance EPP
        set_epp balance_performance

        # Turbo on (OS manages it adaptively)
        echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
        echo "  ✅ Turbo boost: ON (adaptive)"

        # Set NVIDIA to Adaptive
        nvidia-settings -a "[gpu:0]/GPUPowerMizerMode=0" 2>/dev/null || true
        echo "  ✅ GPU: Adaptive"

        # Restore auto fan speed
        legion_cli maximumfanspeed-disable 2>/dev/null || true
        echo "  ✅ Fans: Auto"

        # Restart services
        systemctl start cups 2>/dev/null || true
        systemctl start avahi-daemon 2>/dev/null || true
        echo "  ✅ Restarted: CUPS, Avahi"

        echo ""
        echo "💻 Back to balanced mode."
        ;;

    wallpaper)
        echo "🖼  LIVE WALLPAPER MODE: ON (cool & quiet)"
        echo ""

        # Low power limits — wallpaper only needs GPU decode, not heavy CPU
        set_power_limits 35000000 45000000

        # Power-saving EPP — lets pstate stay low during decode
        set_epp balance_power

        # Turbo on but EPP steers it low unless needed
        echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
        echo "  ✅ Turbo boost: ON (stays low due to EPP)"

        # Set NVIDIA to Adaptive (GPU will idle during wallpaper decode)
        nvidia-settings -a "[gpu:0]/GPUPowerMizerMode=0" 2>/dev/null || true
        echo "  ✅ GPU: Adaptive"

        # Auto fan speed
        legion_cli maximumfanspeed-disable 2>/dev/null || true
        echo "  ✅ Fans: Auto"

        echo ""
        echo "🖼  Wallpaper mode active. Run 'sudo bash ~/.scripts/game-mode.sh off' to return to balanced."
        ;;

    *)
        echo "Usage: sudo bash $0 [on|off|wallpaper]"
        echo "  on        = max performance for gaming (PL1=55W PL2=65W, turbo, max fans)"
        echo "  off       = balanced mode (PL1=45W PL2=55W, cool & efficient)"
        echo "  wallpaper = live wallpaper mode (PL1=35W PL2=45W, quietest)"
        exit 1
        ;;
esac
