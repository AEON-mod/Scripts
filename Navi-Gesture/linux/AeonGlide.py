#!/usr/bin/env python3
"""
==============================================================================
 Project:  AeonGlide — Advanced Mouse Gestures
 Version:  5.0.0
 Platform: Linux (X11) — Python 3.10+
 Requires: pynput, psutil

 Usage:
   pip install -r requirements.txt
   python3 AeonGlide.py

 Notes:
   • Requires an X11 session (Xorg or XWayland).
   • Pure Wayland is NOT supported (pynput cannot intercept mouse events).
   • Run from a terminal or add to your DE's startup applications.
   • For gesture actions, xdotool must be installed:
       sudo apt install xdotool   # Debian / Ubuntu
       sudo dnf install xdotool   # Fedora
       sudo pacman -S xdotool     # Arch
==============================================================================
"""

from __future__ import annotations

import os
import sys
import time
import signal
import shutil
import threading
import subprocess
from dataclasses import dataclass, field
from typing import Optional

# ── Dependency checks ───────────────────────────────────────────────────────

def _check_deps():
    missing = []
    try:
        import pynput  # noqa: F401
    except ImportError:
        missing.append("pynput")
    try:
        import psutil  # noqa: F401
    except ImportError:
        missing.append("psutil")
    if not shutil.which("xdotool"):
        missing.append("xdotool (system package)")
    if missing:
        print(f"✗ Missing dependencies: {', '.join(missing)}")
        print("  Install with:  pip install pynput psutil && sudo apt install xdotool")
        sys.exit(1)

_check_deps()

import psutil  # noqa: E402
from pynput.mouse import Listener as MouseListener, Button  # noqa: E402
from pynput.keyboard import Key, Controller as KbCtrl  # noqa: E402

# ── Wayland guard ───────────────────────────────────────────────────────────

_session = os.environ.get("XDG_SESSION_TYPE", "").lower()
if _session == "wayland":
    # Check for XWayland fallback
    try:
        subprocess.check_output(["xdotool", "getactivewindow"], stderr=subprocess.DEVNULL)
    except Exception:
        print("⚠  AeonGlide requires X11. Pure Wayland is not supported.")
        print("   If you're running GNOME on Wayland, XWayland may still work.")
        print("   Try: export GDK_BACKEND=x11  before launching.")
        sys.exit(1)


# =============================================================================
#  CONFIGURATION
# =============================================================================

@dataclass
class Config:
    click_window: float       = 0.35   # Max seconds between clicks
    single_click_delay: float = 0.22   # Seconds before committing a single right-click
    swipe_threshold: int      = 50     # Min px horizontal drag → swipe
    hold_threshold: float     = 0.30   # Seconds — shorter = tap, longer = hold
    edge_hover_delay: float   = 1.0    # Seconds hovering top edge → overview
    edge_hover_cooldown: float= 1.5    # Cooldown after overview trigger
    game_check_interval: float= 2.0    # Seconds between game-detection polls
    edge_check_interval: float= 0.1    # Seconds between top-edge polls
    version: str              = "5.0.0"


# =============================================================================
#  GAME / APP DETECTION LIST
#  Use process names visible in `ps aux` or `htop`.
# =============================================================================

TARGET_GAMES: list[str] = [
    "valiant-Win64",      # Valorant (via Proton/Wine)
    "cs2_linux64",        # CS2 native
    "minecraft-launcher", # Minecraft
    "FortniteClient",     # Fortnite (via Proton)
    "steam_app_",         # Generic Steam/Proton game prefix
]

# =============================================================================
#  DESKTOP ENVIRONMENT DETECTION
# =============================================================================

def _detect_de() -> str:
    """Return a normalised desktop environment name."""
    de = os.environ.get("XDG_CURRENT_DESKTOP", "").upper()
    if "GNOME" in de or "UNITY" in de:
        return "gnome"
    if "KDE" in de or "PLASMA" in de:
        return "kde"
    if "XFCE" in de:
        return "xfce"
    if "CINNAMON" in de:
        return "cinnamon"
    if "MATE" in de:
        return "mate"
    if "HYPRLAND" in de:
        return "hyprland"
    return "generic"

DE = _detect_de()

# =============================================================================
#  ACTION DISPATCH — DE-aware keyboard shortcuts
# =============================================================================

_kb = KbCtrl()

def _xdotool(*args: str):
    """Fire-and-forget xdotool command."""
    try:
        subprocess.Popen(
            ["xdotool", *args],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except FileNotFoundError:
        pass


def send_copy():
    _xdotool("key", "ctrl+c")

def send_paste():
    _xdotool("key", "ctrl+v")

def send_select_all():
    _xdotool("key", "ctrl+a")

def send_back():
    _xdotool("key", "alt+Left")

def send_forward():
    _xdotool("key", "alt+Right")

def send_clipboard_history():
    """Clipboard history — DE-specific or best-effort."""
    if DE == "gnome":
        # GNOME 45+ has built-in clipboard history or use Clipboard Indicator ext
        _xdotool("key", "super+v")
    elif DE == "kde":
        _xdotool("key", "ctrl+alt+v")  # KDE Klipper default
    else:
        _xdotool("key", "super+v")

def send_screenshot():
    """Region screenshot — DE-specific."""
    if shutil.which("flameshot"):
        subprocess.Popen(["flameshot", "gui"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    elif DE == "gnome":
        _xdotool("key", "shift+Print")
    elif DE == "kde":
        _xdotool("key", "shift+Print")
    else:
        # Fallback: gnome-screenshot or scrot
        if shutil.which("gnome-screenshot"):
            subprocess.Popen(["gnome-screenshot", "-a"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        elif shutil.which("scrot"):
            subprocess.Popen(["scrot", "-s"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def send_task_view():
    """Show all windows / workspace overview."""
    if DE == "gnome":
        _xdotool("key", "super")
    elif DE == "kde":
        _xdotool("key", "ctrl+F10")    # KDE "Show Desktop Grid"
    elif DE == "xfce":
        _xdotool("key", "super+d")
    elif DE == "cinnamon":
        _xdotool("key", "super")
    else:
        _xdotool("key", "super")

def send_right_click():
    """Synthetic right-click at current position."""
    _xdotool("click", "3")


# =============================================================================
#  STATE
# =============================================================================

@dataclass
class State:
    suspended: bool          = False
    game_suspended: bool     = False
    left_held: bool          = False
    combo_mode: bool         = False    # latched at right-down when left is held
    r_clicks: int            = 0
    l_clicks: int            = 0
    right_down_pos: tuple    = (0, 0)
    right_down_time: float   = 0.0
    last_r_click_time: float = 0.0
    last_l_click_time: float = 0.0
    hover_start: float       = 0.0

cfg   = Config()
state = State()

# ── Thread-safe timer handles ───────────────────────────────────────────────

_single_timer: Optional[threading.Timer] = None
_multi_timer:  Optional[threading.Timer] = None
_lock = threading.Lock()

def _cancel_timers():
    global _single_timer, _multi_timer
    if _single_timer:
        _single_timer.cancel()
        _single_timer = None
    if _multi_timer:
        _multi_timer.cancel()
        _multi_timer = None


# =============================================================================
#  MOUSE HANDLER
# =============================================================================

def on_click(x: int, y: int, button: Button, pressed: bool):
    """Handle all mouse button events."""
    global _single_timer, _multi_timer

    if state.suspended:
        return

    now = time.monotonic()

    # ── LEFT BUTTON ─────────────────────────────────────────────────────────
    if button == Button.left:
        if pressed:
            state.left_held = True

            # Triple left-click → Paste
            if now - state.last_l_click_time < cfg.click_window:
                state.l_clicks += 1
            else:
                state.l_clicks = 1
            state.last_l_click_time = now

            if state.l_clicks >= 3:
                send_paste()
                state.l_clicks = 0
        else:
            state.left_held = False
        return

    # ── RIGHT BUTTON ────────────────────────────────────────────────────────
    if button == Button.right:
        if pressed:
            state.right_down_pos  = (x, y)
            state.right_down_time = now
            state.combo_mode      = state.left_held
        else:
            # ── Right release ───────────────────────────────────────────────
            duration = now - state.right_down_time

            # Combo: Left was held when right was pressed
            if state.combo_mode:
                state.combo_mode = False
                if duration > 0.3:
                    send_screenshot()
                else:
                    send_clipboard_history()
                return

            # Swipe detection
            dist_x = x - state.right_down_pos[0]
            if abs(dist_x) > cfg.swipe_threshold:
                if dist_x > 0:
                    send_forward()
                else:
                    send_back()
                state.r_clicks = 0
                with _lock:
                    _cancel_timers()
                return

            # Multi-click state machine
            if now - state.last_r_click_time < cfg.click_window:
                state.r_clicks += 1
            else:
                state.r_clicks = 1
            state.last_r_click_time = now

            with _lock:
                _cancel_timers()

            click_dur = duration

            if state.r_clicks == 1:
                def _finalize_single():
                    with _lock:
                        if state.r_clicks == 1:
                            if click_dur < cfg.hold_threshold:
                                send_right_click()
                            state.r_clicks = 0
                        elif state.r_clicks >= 2:
                            global _multi_timer
                            def _finalize_multi():
                                if state.r_clicks >= 3:
                                    send_select_all()
                                else:
                                    send_copy()
                                state.r_clicks = 0
                            _multi_timer = threading.Timer(0.18, _finalize_multi)
                            _multi_timer.daemon = True
                            _multi_timer.start()

                _single_timer = threading.Timer(cfg.single_click_delay, _finalize_single)
                _single_timer.daemon = True
                _single_timer.start()
        return


# =============================================================================
#  GAME DETECTION THREAD
# =============================================================================

def _game_check_loop():
    """Poll running processes for known game signatures."""
    while True:
        try:
            found = False
            for proc in psutil.process_iter(["name"]):
                pname = proc.info["name"] or ""
                for pattern in TARGET_GAMES:
                    if pattern.lower() in pname.lower():
                        found = True
                        break
                if found:
                    break

            if found and not state.suspended:
                state.suspended = True
                state.game_suspended = True
                _status("paused", "game detected")
            elif not found and state.game_suspended:
                state.suspended = False
                state.game_suspended = False
                _status("active")
        except Exception:
            pass

        time.sleep(cfg.game_check_interval)


# =============================================================================
#  TOP EDGE HOVER THREAD → Task View / Overview
# =============================================================================

def _edge_hover_loop():
    """Poll mouse Y position; if at top pixel for long enough, fire overview."""
    while True:
        if not state.suspended:
            try:
                out = subprocess.check_output(
                    ["xdotool", "getmouselocation"],
                    stderr=subprocess.DEVNULL,
                    text=True,
                )
                # Output: x:123 y:456 screen:0 window:789
                parts = dict(p.split(":") for p in out.strip().split() if ":" in p)
                y = int(parts.get("y", 99))

                if y <= 1:
                    if state.hover_start == 0:
                        state.hover_start = time.monotonic()
                    elif time.monotonic() - state.hover_start > cfg.edge_hover_delay:
                        send_task_view()
                        state.hover_start = 0
                        time.sleep(cfg.edge_hover_cooldown)
                else:
                    state.hover_start = 0
            except Exception:
                state.hover_start = 0

        time.sleep(cfg.edge_check_interval)


# =============================================================================
#  STATUS DISPLAY
# =============================================================================

def _status(mode: str, reason: str = ""):
    label = f"🛸 AeonGlide v{cfg.version}"
    if mode == "active":
        print(f"\r{label} — \033[92m● Active\033[0m          ", end="", flush=True)
    elif mode == "paused":
        extra = f" ({reason})" if reason else ""
        print(f"\r{label} — \033[91m● Paused{extra}\033[0m   ", end="", flush=True)
    elif mode == "exit":
        print(f"\n{label} — \033[93m■ Terminated\033[0m")


# =============================================================================
#  MANUAL TOGGLE  (via SIGUSR1 — send from another terminal: kill -USR1 <pid>)
# =============================================================================

def _toggle_handler(signum, frame):
    if state.game_suspended:
        return  # don't override game-detection pause
    state.suspended = not state.suspended
    _status("paused" if state.suspended else "active", "manual")

signal.signal(signal.SIGUSR1, _toggle_handler)


# =============================================================================
#  CLEAN SHUTDOWN
# =============================================================================

_listener: Optional[MouseListener] = None

def _shutdown(signum=None, frame=None):
    _status("exit")
    _cancel_timers()
    if _listener:
        _listener.stop()
    sys.exit(0)

signal.signal(signal.SIGINT,  _shutdown)
signal.signal(signal.SIGTERM, _shutdown)


# =============================================================================
#  MAIN
# =============================================================================

def main():
    global _listener

    print("=" * 60)
    print(f"  🛸 AeonGlide v{cfg.version} — Linux ({DE.upper()})")
    print(f"  PID: {os.getpid()}  |  Toggle: kill -USR1 {os.getpid()}")
    print(f"  Stop:  Ctrl+C  or  kill {os.getpid()}")
    print("=" * 60)
    _status("active")

    # Background threads
    game_thread = threading.Thread(target=_game_check_loop, daemon=True)
    game_thread.start()

    edge_thread = threading.Thread(target=_edge_hover_loop, daemon=True)
    edge_thread.start()

    # Mouse listener (blocks main thread)
    _listener = MouseListener(on_click=on_click)
    _listener.start()
    _listener.join()


if __name__ == "__main__":
    main()
