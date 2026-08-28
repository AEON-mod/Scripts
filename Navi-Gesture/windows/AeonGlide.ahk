; ==============================================================================
; Project:  AeonGlide — Advanced Mouse Gestures
; Version:  5.0.0
; Platform: Windows (AutoHotkey v2.0+)
; ==============================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook True

; --- AUTO-ADMINISTRATOR ---
if !A_IsAdmin {
    try Run('*RunAs "' A_ScriptFullPath '"')
    ExitApp()
}

; ==============================================================================
; CONFIGURATION
; ==============================================================================

global CFG := {
    clickWindow     : 350,     ; Max ms between clicks for multi-click detection
    singleClickDelay: 200,     ; Ms before committing a single right-click
    swipeThreshold  : 50,      ; Min px of horizontal drag to count as a swipe
    holdThreshold   : 300,     ; Ms — shorter = tap, longer = hold
    edgeHoverDelay  : 1000,    ; Ms hovering the top pixel before Task View fires
    edgeHoverCooldown: 1500,   ; Ms cooldown after Task View trigger
    gameCheckInterval: 2000,   ; Ms between game-detection polls
    edgeCheckInterval: 100,    ; Ms between top-edge hover polls
    version         : "5.0.0"
}

; ==============================================================================
; GAME DETECTION LIST
; Add process names from Task Manager → Details
; ==============================================================================

global TargetGames := [
    "ahk_exe Valorant-Win64-Shipping.exe",
    "ahk_exe Minecraft.exe",
    "ahk_exe FortniteClient-Win64-Shipping.exe",
    "ahk_exe cs2.exe",
]

; ==============================================================================
; INITIALIZATION
; ==============================================================================

A_MaxHotkeysPerInterval := 200
CoordMode("Mouse", "Screen")

; --- Tray Menu ---
A_IconTip := "AeonGlide v" CFG.version " — Active"
TraySetIcon("shell32.dll", 44)

tray := A_TrayMenu
tray.Delete()
tray.Add("AeonGlide v" CFG.version, (*) => "")
tray.Disable("AeonGlide v" CFG.version)
tray.Add()
tray.Add("Pause / Resume", (*) => ToggleSuspend())
tray.Add()
tray.Add("Exit", (*) => ExitApp())

; --- Start Background Timers ---
SetTimer(CheckForGames, CFG.gameCheckInterval)
SetTimer(CheckTopEdge, CFG.edgeCheckInterval)

; --- Startup Toast ---
ToolTip("🛸 AeonGlide v" CFG.version " — Active")
SetTimer(() => ToolTip(), -2500)

; ==============================================================================
; GAME DETECTION — Auto-Suspend Near Anti-Cheat
; ==============================================================================

CheckForGames() {
    for game in TargetGames {
        if WinActive(game) {
            if !A_IsSuspended
                SuspendOn()
            return
        }
    }
    if A_IsSuspended
        SuspendOff()
}

; ==============================================================================
; SUSPEND HELPERS — Keep icon, tooltip & timers in sync
; ==============================================================================

SuspendOn() {
    Suspend(True)
    SetTimer(CheckTopEdge, 0)
    TraySetIcon("shell32.dll", 110)
    A_IconTip := "AeonGlide v" CFG.version " — Paused"
}

SuspendOff() {
    Suspend(False)
    SetTimer(CheckTopEdge, CFG.edgeCheckInterval)
    TraySetIcon("shell32.dll", 44)
    A_IconTip := "AeonGlide v" CFG.version " — Active"
}

ToggleSuspend() {
    if A_IsSuspended
        SuspendOff()
    else
        SuspendOn()
}

ScrollLock::ToggleSuspend()

; ==============================================================================
; LEFT CLICK — Triple Click → Paste
; ==============================================================================

~LButton:: {
    static clickCount := 0

    if (A_PriorHotkey = "~LButton" && A_TimeSincePriorHotkey < CFG.clickWindow)
        clickCount++
    else
        clickCount := 1

    if (clickCount = 3) {
        Send("^v")
        clickCount := 0
    }
}

; ==============================================================================
; RIGHT BUTTON — Master Gesture Handler
;
;   Single click    →  Context menu (native)
;   Double click    →  Copy          (Ctrl+C)
;   Triple click    →  Select All    (Ctrl+A)
;   Swipe L / R     →  Back / Forward
;   Left+Tap Right  →  Clipboard History   (Win+V)
;   Left+Hold Right →  Snipping Tool       (Win+Shift+S)
; ==============================================================================

RButton:: {
    static rClicks := 0

    MouseGetPos(&x1, &y1)
    pressStart := A_TickCount

    ; ── Combo: Left held + Right pressed ────────────────────────────────────
    if GetKeyState("LButton", "P") {
        timedOut := !KeyWait("RButton", "T0.3")
        if timedOut
            Send("#+s")
        else
            Send("#v")
        KeyWait("RButton")
        return
    }

    ; ── Wait for release & measure ──────────────────────────────────────────
    KeyWait("RButton")
    pressDuration := A_TickCount - pressStart
    MouseGetPos(&x2, &y2)

    ; ── Swipe Detection ─────────────────────────────────────────────────────
    distX := x2 - x1
    if (Abs(distX) > CFG.swipeThreshold) {
        Send(distX > 0 ? "!{Right}" : "!{Left}")
        rClicks := 0
        return
    }

    ; ── Multi-Click State Machine ───────────────────────────────────────────
    if (A_PriorHotkey = "RButton" && A_TimeSincePriorHotkey < CFG.clickWindow)
        rClicks++
    else
        rClicks := 1

    ; Snapshot duration so the timer callback reads the correct value
    clickDur := pressDuration

    if (rClicks = 1) {
        SetTimer(FinalizeClick.Bind(clickDur), -CFG.singleClickDelay)
    }

    FinalizeClick(dur) {
        if (rClicks = 1) {
            if (dur < CFG.holdThreshold)
                Click("Right")
            rClicks := 0
        } else if (rClicks >= 2) {
            SetTimer(FinalizeMulti, -180)
        }
    }

    FinalizeMulti() {
        if (rClicks >= 3)
            Send("^a")
        else
            Send("^c")
        rClicks := 0
    }
}

; ==============================================================================
; TOP EDGE HOVER → Task View  (Win+Tab)
; ==============================================================================

CheckTopEdge() {
    static hoverStart := 0

    MouseGetPos(, &y)
    if (y <= 1) {
        if (hoverStart = 0)
            hoverStart := A_TickCount
        else if (A_TickCount - hoverStart > CFG.edgeHoverDelay) {
            Send("#{Tab}")
            hoverStart := 0
            Sleep(CFG.edgeHoverCooldown)
        }
    } else {
        hoverStart := 0
    }
}

; ==============================================================================
; KILL SWITCH — Shift+Escape
; ==============================================================================

+Esc::ExitApp()
