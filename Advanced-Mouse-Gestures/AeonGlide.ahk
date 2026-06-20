; ==============================================================================
; Project: AEON-mod (Advanced Mouse Gestures)
; Version: 4.3.1 (Auto-Game Pause)
; ==============================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

; --- AUTO-ADMINISTRATOR ---
if !A_IsAdmin {
    Run('*RunAs "' A_ScriptFullPath '"')
    ExitApp()
}

; --- SETTINGS ---
T := 400 
SwipeDist := 50 

; --- GAME DETECTION LIST ---
; Add your game process names here (find them in Task Manager -> Details)
TargetGames := "ahk_exe Valorant-Win64-Shipping.exe, ahk_exe Minecraft.exe, ahk_exe FortniteClient-Win64-Shipping.exe, ahk_exe cs2.exe"

; Check every 2 seconds if a game is active
SetTimer(CheckForGames, 2000)

CheckForGames() {
    Loop Parse, TargetGames, ","
    {
        if WinActive(Trim(A_LoopField)) {
            if !A_IsSuspended {
                Suspend(True) ; Pause all hotkeys for Anti-Cheat safety
                TraySetIcon("shell32.dll", 110) ; Change icon to "Paused" (Red X)
            }
            return
        }
    }
    
    ; If no games are active, resume normal operation
    if A_IsSuspended {
        Suspend(False)
        TraySetIcon() ; Restore original Green H icon
    }
}

; --- MANUAL OVERRIDE (Toggle) ---
ScrollLock::Suspend ; Press Scroll Lock if you want to pause it manually

; --- THE "IGNORE" REGION ---
~*XButton1::return
~*XButton2::return
~*MButton::return

; --- LEFT CLICK: TRIPLE CLICK PASTE ---
~LButton:: {
    static lClicks := 0
    if (A_PriorHotkey = "~LButton" and A_TimeSincePriorHotkey < T)
        lClicks++
    else
        lClicks := 1

    if (lClicks = 3) {
        Send "^v" 
        lClicks := 0
    }
}

; --- THE MASTER RBUTTON HANDLER ---
RButton:: {
    static rClicks := 0
    MouseGetPos(&x1, &y1)
    Start := A_TickCount
    
    if GetKeyState("LButton", "P") {
        timedOut := !KeyWait("RButton", "T0.3") 
        if (timedOut)
            Send "#+s"
        else
            Send "#v"
        KeyWait "RButton" 
        return
    }

    KeyWait "RButton"
    Duration := A_TickCount - Start
    MouseGetPos(&x2, &y2)
    
    distX := x2 - x1
    if (Abs(distX) > SwipeDist) {
        if (distX > 0)
            Send "!{Right}"
        else
            Send "!{Left}"
        rClicks := 0
        return
    }

    if (A_PriorHotkey = "RButton" and A_TimeSincePriorHotkey < T)
        rClicks++
    else
        rClicks := 1

    if (rClicks = 1) {
        SetTimer(CheckMultiClick, -250) 
    }
    
    CheckMultiClick() {
        if (rClicks = 2) {
            SetTimer(CheckTripleClick, -200)
        } else if (rClicks = 1) {
            if (Duration < 300)
                Click "Right"
        }
    }

    CheckTripleClick() {
        if (rClicks = 3) {
            Send "{Ctrl down}a{Ctrl up}"
            rClicks := 0
        } else {
            Send "^{c}"
            rClicks := 0
        }
    }

; --- TOP EDGE: TAB OVERVIEW ---
SetTimer(CheckTopEdge, 100)
CheckTopEdge() {
    static HoverStart := 0
    
    ; The Fix: Use braces for the 'if' statement to satisfy AHK v2
    if (A_IsSuspended) {
        return 
    }
    
    MouseGetPos(, &y)
    if (y <= 1) {
        if (HoverStart = 0) 
            HoverStart := A_TickCount
        else if (A_TickCount - HoverStart > 1000) {
            Send "#{Tab}"
            HoverStart := 0
            Sleep 1500 
        }
    } else {
        HoverStart := 0
    }
}
; --- KILL SWITCH ---
+Esc::ExitApp()
