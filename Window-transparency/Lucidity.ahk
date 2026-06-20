; ============================================================
;  AEON-Transparency Manager  —  AHK v2
;  Optimized for GlazeWM, Komorebi, & AEON-mod
; ============================================================

#Requires AutoHotkey v2.0
#SingleInstance Force
SetWorkingDir A_ScriptDir

; ─── Settings ───────────────────────────────────────────────
CONFIG_FILE   := A_ScriptDir . "\TransparencySettings.ini"
INI_SECTION   := "AppCapacities"
STEP := 15, MIN_TRANS := 30, MAX_TRANS := 255, DEFAULT_TRANS := 220

; ─── State Maps ─────────────────────────────────────────────
global transparencyLevels := Map() 
global needsSaving        := false

; ─── Initialization ─────────────────────────────────────────
LoadSettings()
SetTimer(SyncEngine, 400)      ; Keeps TWMs from resetting styles
SetTimer(BufferedSave, 20000)   ; Protects SSD from frequent writes
A_IconTip := "AEON Transparency Manager"

; ============================================================
;  HOTKEYS
; ============================================================

^+LButton:: ShowAppGui()     ; UI to set capacity for current app
^+NumpadAdd:: Adjust(1)      ; Increase capacity (more opaque)
^+NumpadSub:: Adjust(-1)     ; Decrease capacity (more transparent)
^+NumpadMult:: ResetApp()    ; Reset app to 100% (Removes from config)

; ============================================================
;  CORE ENGINE
; ============================================================

SyncEngine() {
    ; Loop through all processes with saved capacities
    for proc, level in transparencyLevels {
        for wid in WinGetList("ahk_exe " . proc) {
            try {
                if !IsWindowValid(wid)
                    continue
                
                ; Force transparency if TWM or system reset it
                if (WinGetTransparent("ahk_id " . wid) != level) {
                    WinSetTransparent(level, "ahk_id " . wid)
                }
            }
        }
    }
}

Adjust(dir) {
    proc := SafeGetProc()
    if (proc == "") 
        return
    
    cur := transparencyLevels.Has(proc) ? transparencyLevels[proc] : DEFAULT_TRANS
    newVal := Max(MIN_TRANS, Min(MAX_TRANS, cur + (dir * STEP)))
    
    transparencyLevels[proc] := newVal
    global needsSaving := true
    ShowTip(proc . ": " . Round((newVal / 255) * 100) . "%")
}

ResetApp() {
    proc := SafeGetProc()
    if (proc == "") 
        return
    
    if transparencyLevels.Has(proc) {
        transparencyLevels.Delete(proc)
        try IniDelete(CONFIG_FILE, INI_SECTION, proc)
    }
    
    for wid in WinGetList("ahk_exe " . proc) {
        try WinSetTransparent(255, "ahk_id " . wid)
    }
        
    ShowTip(proc . ": Reset to 100%")
}

; ============================================================
;  GUI (Catppuccin Mocha Palette)
; ============================================================

ShowAppGui() {
    proc := SafeGetProc()
    if (proc == "") 
        return
    
    cur := transparencyLevels.Has(proc) ? transparencyLevels[proc] : DEFAULT_TRANS
    
    g := Gui("+AlwaysOnTop -MaximizeBox", "AEON: " . proc)
    g.BackColor := "0x1E1E2E"
    g.SetFont("c0xCDD6F4 s10", "Segoe UI")
    
    g.AddText("w220 Center", "Process: " . proc)
    sld := g.AddSlider("w220 Range30-255 AltSubmit", cur)
    
    btn := g.AddButton("w220 h35", "Apply & Save")
    btn.SetFont("Bold")
    
    ; Define the click behavior properly for v2
    btn.OnEvent("Click", SaveAndClose)
    
    SaveAndClose(*) {
        global needsSaving := true
        transparencyLevels[proc] := sld.Value
        g.Destroy()
        ShowTip("Saved: " . proc)
    }
    
    g.Show()
}
; ============================================================
;  SYSTEM & IO
; ============================================================

IsWindowValid(wid) {
    try {
        style := WinGetStyle("ahk_id " . wid)
        cls := WinGetClass("ahk_id " . wid)
        ; Ignore shell components and TWM bars
        if (cls ~= "i)Shell_TrayWnd|WorkerW|Progman|Komobar|GlazeWM|TaskSwitcherWnd")
            return false
        return (style & 0x10000000) ; Must be WS_VISIBLE
    }
    return false
}

LoadSettings() {
    if !FileExist(CONFIG_FILE) 
        return
    try {
        rawSection := IniRead(CONFIG_FILE, INI_SECTION)
        for line in StrSplit(rawSection, "`n") {
            kv := StrSplit(line, "=")
            if (kv.Length == 2) {
                transparencyLevels[StrLower(kv[1])] := Number(kv[2])
            }
        }
    }
}

BufferedSave() {
    global needsSaving
    if !needsSaving 
        return
    for proc, val in transparencyLevels {
        IniWrite(val, CONFIG_FILE, INI_SECTION, proc)
    }
    needsSaving := false
}

SafeGetProc() => (WinExist("A") ? StrLower(WinGetProcessName("A")) : "")
ShowTip(txt) => (ToolTip(txt), SetTimer(() => ToolTip(), -1200))