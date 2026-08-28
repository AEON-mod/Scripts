; ============================================================================
; Touchpad Toggle — Windows (AutoHotkey v2)
; ============================================================================
; Hotkey: Win + Ctrl + L
; Toggles the touchpad (HID-compliant touch pad) on or off.
;
; Requirements:
;   - AutoHotkey v2 (https://www.autohotkey.com/)
;   - Run as Administrator (required to disable/enable devices)
;
; Installation:
;   1. Install AutoHotkey v2
;   2. Right-click this file → Run as Administrator
;   3. (Optional) Place a shortcut in shell:startup to auto-run at login
; ============================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

; ── State tracker ──
global TouchpadDisabled := false

; ── Hotkey: Win + Ctrl + L ──
#^l:: {
    global TouchpadDisabled
    ToggleTouchpad()
}

ToggleTouchpad() {
    global TouchpadDisabled

    if (TouchpadDisabled) {
        ; Enable the touchpad
        result := RunPowerShell("Enable")
        if (result = 0) {
            TouchpadDisabled := false
            TrayTip("Touchpad Enabled", "👆 Touchpad has been turned ON", 1)
        } else {
            TrayTip("Error", "Failed to enable touchpad", 3)
        }
    } else {
        ; Disable the touchpad
        result := RunPowerShell("Disable")
        if (result = 0) {
            TouchpadDisabled := true
            TrayTip("Touchpad Disabled", "✋ Touchpad has been turned OFF", 1)
        } else {
            TrayTip("Error", "Failed to disable touchpad", 3)
        }
    }
}

RunPowerShell(action) {
    ; Build PowerShell command to find and toggle the touchpad device
    if (action = "Disable") {
        psCmd := "
        (
            $tp = Get-PnpDevice -Class 'HIDClass' -Status 'OK' |
                Where-Object { $_.FriendlyName -match 'touch\s?pad|track\s?pad|precision|HID-compliant touch' } |
                Select-Object -First 1
            if ($tp) {
                Disable-PnpDevice -InstanceId $tp.InstanceId -Confirm:$false
                exit 0
            } else {
                # Fallback: try Mouse class
                $tp = Get-PnpDevice -Class 'Mouse' -Status 'OK' |
                    Where-Object { $_.FriendlyName -match 'touch\s?pad|track\s?pad|precision' } |
                    Select-Object -First 1
                if ($tp) {
                    Disable-PnpDevice -InstanceId $tp.InstanceId -Confirm:$false
                    exit 0
                }
                exit 1
            }
        )"
    } else {
        psCmd := "
        (
            $tp = Get-PnpDevice -Class 'HIDClass' |
                Where-Object { $_.FriendlyName -match 'touch\s?pad|track\s?pad|precision|HID-compliant touch' } |
                Select-Object -First 1
            if ($tp) {
                Enable-PnpDevice -InstanceId $tp.InstanceId -Confirm:$false
                exit 0
            } else {
                $tp = Get-PnpDevice -Class 'Mouse' |
                    Where-Object { $_.FriendlyName -match 'touch\s?pad|track\s?pad|precision' } |
                    Select-Object -First 1
                if ($tp) {
                    Enable-PnpDevice -InstanceId $tp.InstanceId -Confirm:$false
                    exit 0
                }
                exit 1
            }
        )"
    }

    ; Run PowerShell hidden and wait for result
    shell := ComObject("WScript.Shell")
    exec := shell.Run('powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "' psCmd '"', 0, true)
    return exec
}

; ── Tray menu ──
A_IconTip := "Touchpad Toggle (Win+Ctrl+L)"

trayMenu := A_TrayMenu
trayMenu.Delete()
trayMenu.Add("Toggle Touchpad", (*) => ToggleTouchpad())
trayMenu.Add()
trayMenu.Add("Exit", (*) => ExitApp())
