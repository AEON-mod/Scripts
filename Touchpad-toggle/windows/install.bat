@echo off
:: ============================================================================
:: Touchpad Toggle — Windows Installer
:: ============================================================================
:: Installs the AutoHotkey toggle script and optionally adds it to startup.
::
:: Requirements: AutoHotkey v2 must be installed.
:: Run this script as Administrator.
:: ============================================================================

echo.
echo  ╔══════════════════════════════════════════════╗
echo  ║   Touchpad Toggle — Windows Installer        ║
echo  ╚══════════════════════════════════════════════╝
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] This installer must be run as Administrator.
    echo         Right-click and select "Run as administrator".
    pause
    exit /b 1
)

:: Check if AutoHotkey is installed
where autohotkey >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARNING] AutoHotkey v2 does not appear to be installed.
    echo           Download it from: https://www.autohotkey.com/
    echo.
    set /p CONTINUE="Continue anyway? (y/n): "
    if /i not "%CONTINUE%"=="y" exit /b 1
)

:: Set install directory
set "INSTALL_DIR=%USERPROFILE%\TouchpadToggle"
set "SCRIPT_NAME=touchpad-toggle.ahk"

:: Create install directory
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

:: Copy the script
copy /y "%~dp0touchpad-toggle.ahk" "%INSTALL_DIR%\%SCRIPT_NAME%" >nul
echo [OK] Installed script to: %INSTALL_DIR%\%SCRIPT_NAME%

:: Ask about startup
echo.
set /p STARTUP="Add to Windows startup? (y/n): "
if /i "%STARTUP%"=="y" (
    set "STARTUP_DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
    :: Create a shortcut in the startup folder
    powershell -NoProfile -Command ^
        "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%STARTUP_DIR%\TouchpadToggle.lnk'); $s.TargetPath = '%INSTALL_DIR%\%SCRIPT_NAME%'; $s.WorkingDirectory = '%INSTALL_DIR%'; $s.Description = 'Touchpad Toggle (Win+Ctrl+L)'; $s.Save()"
    echo [OK] Added to startup. Script will run automatically on login.
)

echo.
echo  ════════════════════════════════════════════════
echo  [OK] Installation complete!
echo.
echo   Script location:  %INSTALL_DIR%\%SCRIPT_NAME%
echo   Keyboard shortcut: Win + Ctrl + L
echo.
echo   To start now, double-click the script.
echo   NOTE: Must run as Administrator for device toggling.
echo  ════════════════════════════════════════════════
echo.
pause
