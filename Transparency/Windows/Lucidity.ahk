; ============================================================
;  Lucidity  —  AEON Transparency Manager  —  AHK v2
;  Per-app window opacity for GlazeWM, Komorebi, & AEON-mod
; ============================================================

#Requires AutoHotkey v2.0
#SingleInstance Force
SetWorkingDir A_ScriptDir

; ─── Settings ───────────────────────────────────────────────
CONFIG_FILE   := A_ScriptDir . "\TransparencySettings.ini"
INI_SECTION   := "AppCapacities"
PIN_SECTION   := "PinnedApps"

STEP          := 15
MIN_TRANS     := 30
MAX_TRANS     := 255
DEFAULT_TRANS := 220
SYNC_INTERVAL := 800       ; ms between sync cycles (was 400 — kinder to CPU)
SAVE_INTERVAL := 20000     ; ms between buffered disk writes

; ─── Filtered Window Classes ────────────────────────────────
; These are never touched by the engine to prevent UI breakage.
GHOST_CLASSES := "i)Shell_TrayWnd|WorkerW|Progman|Komobar|GlazeWM"
             .   "|TaskSwitcherWnd|Windows\.UI\.Core|ApplicationFrameWindow"
             .   "|ForegroundStaging|NotifyIconOverflowWindow"

; ─── State Maps ─────────────────────────────────────────────
global transparencyLevels := Map()
global pinnedWindows      := Map()   ; proc → true
global disabledApps       := Map()   ; proc → true  (transparency paused)
global needsSaving        := false

; ─── Initialization ─────────────────────────────────────────
LoadSettings()
SetTimer(SyncEngine, SYNC_INTERVAL)
SetTimer(BufferedSave, SAVE_INTERVAL)

BuildTrayMenu()
OnExit(ExitCleanup)

; ============================================================
;  HOTKEYS
; ============================================================

^+LButton::    ShowAppGui()       ; Open Lucidity GUI for current app
^+NumpadAdd::  Adjust(1)          ; Increase opacity (+STEP)
^+NumpadSub::  Adjust(-1)         ; Decrease opacity (-STEP)
^+NumpadMult:: ResetApp()         ; Reset to 100% & remove from config
^+Space::      TogglePin()        ; Toggle Always-On-Top
^+RButton::    ToggleTransparency()  ; Toggle transparency ON/OFF

; ============================================================
;  CORE ENGINE
; ============================================================

SyncEngine() {
    for proc, level in transparencyLevels {
        ; Skip apps whose transparency is paused
        if disabledApps.Has(proc)
            continue

        try winList := WinGetList("ahk_exe " . proc)
        catch
            continue

        for wid in winList {
            try {
                if !IsWindowValid(wid)
                    continue

                ; WinGetTransparent returns "" for non-layered windows.
                ; Treat "" as fully opaque (255).
                current := WinGetTransparent("ahk_id " . wid)
                current := (current == "") ? 255 : current

                if (current != level)
                    WinSetTransparent(level, "ahk_id " . wid)
            }
        }
    }

    ; Enforce pinned state (TWMs love to strip WS_EX_TOPMOST)
    for proc, _ in pinnedWindows {
        try {
            for wid in WinGetList("ahk_exe " . proc) {
                if !IsWindowValid(wid)
                    continue
                exStyle := WinGetExStyle("ahk_id " . wid)
                if !(exStyle & 0x8)   ; WS_EX_TOPMOST
                    WinSetAlwaysOnTop(true, "ahk_id " . wid)
            }
        }
    }
}

Adjust(dir) {
    proc := SafeGetProc()
    if (proc == "")
        return

    cur    := transparencyLevels.Has(proc) ? transparencyLevels[proc] : MAX_TRANS
    newVal := Clamp(cur + (dir * STEP), MIN_TRANS, MAX_TRANS)

    transparencyLevels[proc] := newVal
    global needsSaving := true
    ShowTip(proc . ": " . TransToPercent(newVal) . "%")
}

ResetApp() {
    proc := SafeGetProc()
    if (proc == "")
        return

    if transparencyLevels.Has(proc) {
        transparencyLevels.Delete(proc)
        try IniDelete(CONFIG_FILE, INI_SECTION, proc)
    }

    ; Also un-pause if it was paused
    disabledApps.Delete(proc)

    ; Restore all windows of this process to fully opaque
    try {
        for wid in WinGetList("ahk_exe " . proc)
            WinSetTransparent("Off", "ahk_id " . wid)
    }

    ShowTip(proc . ": Reset to 100%")
}

TogglePin() {
    proc := SafeGetProc()
    if (proc == "")
        return

    if pinnedWindows.Has(proc) {
        pinnedWindows.Delete(proc)
        try {
            for wid in WinGetList("ahk_exe " . proc)
                WinSetAlwaysOnTop(false, "ahk_id " . wid)
        }
        global needsSaving := true
        ShowTip(proc . ": Unpinned")
    } else {
        pinnedWindows[proc] := true
        try {
            for wid in WinGetList("ahk_exe " . proc)
                WinSetAlwaysOnTop(true, "ahk_id " . wid)
        }
        global needsSaving := true
        ShowTip(proc . ": Pinned (Always-On-Top)")
    }
}

ToggleTransparency() {
    proc := SafeGetProc()
    if (proc == "")
        return

    if !transparencyLevels.Has(proc) {
        ShowTip(proc . ": No transparency configured")
        return
    }

    if disabledApps.Has(proc) {
        ; Re-enable — SyncEngine will reapply on next tick
        disabledApps.Delete(proc)
        ShowTip(proc . ": Transparency ON")
    } else {
        ; Pause — restore to fully opaque immediately
        disabledApps[proc] := true
        try {
            for wid in WinGetList("ahk_exe " . proc)
                WinSetTransparent("Off", "ahk_id " . wid)
        }
        ShowTip(proc . ": Transparency OFF")
    }
}

; ============================================================
;  GUI  (Catppuccin Mocha Palette)
; ============================================================

ShowAppGui() {
    proc := SafeGetProc()
    if (proc == "")
        return

    cur := transparencyLevels.Has(proc) ? transparencyLevels[proc] : DEFAULT_TRANS

    ; ─── Window ─────────────────────────────────────────────
    g := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox", "Lucidity — " . proc)
    g.BackColor  := "0x1E1E2E"          ; Catppuccin Base
    g.MarginX    := 18
    g.MarginY    := 14

    ; ─── Title ──────────────────────────────────────────────
    g.SetFont("c0xCBA6F7 s12 Bold", "Segoe UI")     ; Mauve
    g.AddText("w260 Center", "✦ Lucidity")

    ; ─── Process Label ──────────────────────────────────────
    g.SetFont("c0xA6ADC8 s9 Norm", "Segoe UI")      ; Subtext0
    g.AddText("w260 Center", "Process: " . proc)

    ; ─── Percentage Display ─────────────────────────────────
    g.SetFont("c0xCDD6F4 s22 Bold", "Segoe UI")     ; Text
    pctLabel := g.AddText("w260 Center vPctLabel", TransToPercent(cur) . "%")

    ; ─── Slider ─────────────────────────────────────────────
    g.SetFont("c0xCDD6F4 s10 Norm", "Segoe UI")
    sld := g.AddSlider("w260 Range" . MIN_TRANS . "-" . MAX_TRANS . " TickInterval15 AltSubmit vSlider", cur)

    ; Live-update the percentage label while dragging
    sld.OnEvent("Change", (*) => pctLabel.Text := TransToPercent(sld.Value) . "%")

    ; ─── Buttons Row ────────────────────────────────────────
    g.SetFont("c0x1E1E2E s10 Bold", "Segoe UI")

    btnApply := g.AddButton("w125 h34", "Apply && Save")
    btnApply.Opt("+Background0xA6E3A1")              ; Green

    btnReset := g.AddButton("x+10 w125 h34", "Reset 100%")
    btnReset.Opt("+Background0xF38BA8")              ; Red

    ; ─── Event Handlers ─────────────────────────────────────
    btnApply.OnEvent("Click", ApplyAndClose)
    btnReset.OnEvent("Click", ResetAndClose)
    g.OnEvent("Escape", (*) => g.Destroy())

    ApplyAndClose(*) {
        transparencyLevels[proc] := sld.Value
        global needsSaving := true
        g.Destroy()
        ShowTip("Saved: " . proc . " → " . TransToPercent(sld.Value) . "%")
    }

    ResetAndClose(*) {
        if transparencyLevels.Has(proc) {
            transparencyLevels.Delete(proc)
            try IniDelete(CONFIG_FILE, INI_SECTION, proc)
        }
        disabledApps.Delete(proc)
        try {
            for wid in WinGetList("ahk_exe " . proc)
                WinSetTransparent("Off", "ahk_id " . wid)
        }
        g.Destroy()
        ShowTip(proc . ": Reset to 100%")
    }

    g.Show()
}

; ============================================================
;  TRAY MENU
; ============================================================

BuildTrayMenu() {
    A_IconTip := "Lucidity — AEON Transparency Manager"
    tray := A_TrayMenu
    tray.Delete()                                     ; Clear defaults
    tray.Add("Lucidity v1.1", (*) => 0)
    tray.Disable("Lucidity v1.1")
    tray.Add()                                        ; Separator
    tray.Add("Reload Script", (*) => Reload())
    tray.Add("Open Config File", OpenConfig)
    tray.Add("Open Config Folder", (*) => Run(A_ScriptDir))
    tray.Add()
    tray.Add("Exit", (*) => ExitApp())
}

OpenConfig(*) {
    if FileExist(CONFIG_FILE)
        Run(CONFIG_FILE)
    else
        MsgBox("No config file yet.`nAdjust a window first.", "Lucidity", "Iconi")
}

; ============================================================
;  SYSTEM & IO
; ============================================================

IsWindowValid(wid) {
    try {
        style := WinGetStyle("ahk_id " . wid)
        cls   := WinGetClass("ahk_id " . wid)

        ; Ignore ghost/system windows
        if (cls ~= GHOST_CLASSES)
            return false

        ; Must have WS_VISIBLE
        return (style & 0x10000000) != 0
    }
    return false
}

LoadSettings() {
    if !FileExist(CONFIG_FILE)
        return

    ; Load transparency levels
    try {
        rawSection := IniRead(CONFIG_FILE, INI_SECTION)
        for line in StrSplit(rawSection, "`n") {
            line := Trim(line)
            if (line == "")
                continue
            kv := StrSplit(line, "=",, 2)
            if (kv.Length == 2) {
                key := Trim(StrLower(kv[1]))
                val := Trim(kv[2])
                if IsNumber(val)
                    transparencyLevels[key] := Clamp(Number(val), MIN_TRANS, MAX_TRANS)
            }
        }
    }

    ; Load pinned apps
    try {
        rawPins := IniRead(CONFIG_FILE, PIN_SECTION)
        for line in StrSplit(rawPins, "`n") {
            line := Trim(line)
            if (line == "")
                continue
            kv := StrSplit(line, "=",, 2)
            if (kv.Length == 2 && Trim(kv[2]) == "1")
                pinnedWindows[Trim(StrLower(kv[1]))] := true
        }
    }
}

BufferedSave() {
    global needsSaving
    if !needsSaving
        return

    ; Write transparency levels
    for proc, val in transparencyLevels
        IniWrite(val, CONFIG_FILE, INI_SECTION, proc)

    ; Write pinned state
    for proc, _ in pinnedWindows
        IniWrite(1, CONFIG_FILE, PIN_SECTION, proc)

    needsSaving := false
}

ExitCleanup(exitReason, exitCode) {
    ; Flush any unsaved state to disk before quitting
    global needsSaving
    if needsSaving {
        for proc, val in transparencyLevels
            IniWrite(val, CONFIG_FILE, INI_SECTION, proc)
        for proc, _ in pinnedWindows
            IniWrite(1, CONFIG_FILE, PIN_SECTION, proc)
    }
}

; ============================================================
;  UTILITIES
; ============================================================

SafeGetProc() {
    try {
        if WinExist("A")
            return StrLower(WinGetProcessName("A"))
    }
    return ""
}

TransToPercent(val) => Round((val / 255) * 100)
Clamp(val, lo, hi) => Max(lo, Min(hi, val))

ShowTip(txt) {
    ToolTip(txt)
    SetTimer(() => ToolTip(), -1500)
}
