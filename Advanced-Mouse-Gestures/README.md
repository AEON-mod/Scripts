# 🛸 AeonGlide
### *The Workflow Exploit.*
**Windows is the bottleneck. AeonGlide is the bypass.** Let's be real: reaching for the keyboard for basic commands is a legacy habit for standard users. **AeonGlide** is a system-level "cheat" that injects custom input logic directly into your mouse. It re-wires how your hardware communicates with the OS, giving you an unfair speed advantage by keeping your hands exactly where they belong.
## 🚀 The Advantage
 * **Custom Input Injection:** Forget the standard Ctrl+C/V or Win+Tab grind. AeonGlide maps high-speed, custom-defined macros to intuitive mouse triggers, allowing you to out-maneuver any standard setup.
 * **Stealth Protocol:** Operates as a silent background hook. No UI, no bloat, no footprint. It’s a "ghost" utility that provides elite-tier functionality without the "gamer-brand" software tax.
 * **Gamer-Safe Bypass:** Built with an "Anti-Detection" timer. The script recognizes game-engine signatures and self-suspends instantly, ensuring your competitive integrity stays clean while your desktop workflow stays "cheated."
 * **System Overclock:** Navigate, select, and execute with 300% more efficiency. With AeonGlide, you aren't just using a PC—you're operating a custom-tuned machine
## ✨ The Gesture Library
| Action | Mouse Input | Result |
|---|---|---|
| **📋 Copy** | Double Right Click | Instantly copy selection |
| **✅ Select All** | Triple Right Click | Highlight everything |
| **📥 Paste** | Triple Left Click | Paste from clipboard |
| **🧭 Navigate** | Right Click + Swipe | Left = Back | Right = Forward |
| **🗂️ History** | Hold Left + Tap Right | Open Clipboard History |
| **📸 Screenshot** | Hold Left + Hold Right | Trigger Snipping Tool |
| **🖥️ Task View** | Hover Top Edge (1s) | See all open windows |
## 🎮 Intelligence: "Gamer-Safe" Mode
**AeonGlide** is built for enthusiasts. It features a **Smart-Sense Timer** that detects when you are in a game and automatically **Suspends** itself.
 * **100% Anti-Cheat Compatible:** It stops "hooking" your mouse when a game is active.
 * **Visual Feedback:** The tray icon turns **🔴 Red (Paused)** when gaming and **🟢 Green (Active)** on your desktop.
### 🛠️ Adding Your Games
 1. Open **Task Manager** (Ctrl+Shift+Esc).
 2. Go to **Details** and find your game (e.g., Overwatch.exe).
 3. Open AeonGlide.ahk and add it to the TargetGames list:
   > TargetGames := "ahk_exe Valorant.exe, ahk_exe Overwatch.exe"
   > 
 4. **For a quick startup (Easy Method):** Drop the script (or a shortcut to it) into the Windows Startup folder:
   > C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup
   > 
## 🛡️ Setup (The "Pro" Way)
To make **AeonGlide** feel like a built-in Windows feature (running with Admin rights but without the annoying popups):
 1. Open **Task Scheduler** and **Create Task**.
 2. **General:** Check Run with highest privileges.
 3. **Triggers:** Set to At log on.
 4. **Actions:** * Program: Browse to AutoHotkey64.exe (C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe)
   * Arguments: Paste the path to your script: "C:\...\AeonGlide.ahk"
 5. **Conditions:** Uncheck Start only if on AC power.
## 🛑 Control Center
 * **Pause/Resume:** Scroll Lock (Manual toggle)
 * **Instant Kill:** Shift + Escape (Panic button)
### 📡 Developer Note
Designed for the **AEON-mod** ecosystem. If you’re a coder, digital creator, or just a power user, this is the missing piece of your Windows experience.
**Ready to fly?** Just run the script. 🖱️✨
