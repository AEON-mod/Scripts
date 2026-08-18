<div align="center">

# 🌐 Browser Auto-Integration
**Send all web browser downloads to the 16-connection Net-Booster engine automatically.**

</div>

---

If you don't want to copy and paste links into the terminal using the `dl` command, you can set up `aria2` to run silently in the background. With a browser extension, every time you click "Download" in Chrome, Edge, or Firefox, it will automatically be accelerated by Net-Booster.

## Step 1: Update your configuration

Open your `aria2.conf` file (located at `~/.config/aria2/aria2.conf` on Linux/macOS or `%USERPROFILE%\.config\aria2\aria2.conf` on Windows) and add these lines to the bottom:

```ini
# --- RPC Daemon Settings ---
enable-rpc=true
rpc-listen-all=false
rpc-listen-port=6800

# VERY IMPORTANT: Set your download directory!
# Replace "YourUsername" with your actual username.
# Linux/macOS example: dir=/home/YourUsername/Downloads
# Windows example: dir=C:\Users\YourUsername\Downloads
dir=/path/to/your/Downloads
```

## Step 2: Set it to auto-start silently

We need `aria2` to turn on automatically in the background when you start your computer.

### 🐧 Linux (systemd)
Open a terminal and run:
```bash
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/aria2-daemon.service << 'SERVICE'
[Unit]
Description=Aria2c RPC Daemon
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/aria2c --conf-path=%h/.config/aria2/aria2.conf
Restart=on-failure

[Install]
WantedBy=default.target
SERVICE

systemctl --user daemon-reload
systemctl --user enable --now aria2-daemon.service
```

### 🪟 Windows (Startup Folder)
1. Press `Win + R`, type `shell:startup` and hit Enter.
2. Right-click inside the folder -> **New** -> **Text Document**.
3. Name it `aria2-daemon.vbs` (make sure to remove the `.txt` extension).
4. Right-click it, select **Edit**, and paste this code:
```vbscript
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "aria2c --conf-path=""" & CreateObject("wscript.shell").ExpandEnvironmentStrings("%USERPROFILE%") & "\.config\aria2\aria2.conf""", 0, False
```
*(The `0` makes it run completely invisibly without a terminal window).* Double-click the script to start it right now.

### 🍎 macOS (LaunchAgent)
Open a terminal and run:
```bash
cat > ~/Library/LaunchAgents/com.aria2.daemon.plist << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.aria2.daemon</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/aria2c</string>
        <string>--conf-path</string>
        <string>/Users/YOUR_USERNAME/.config/aria2/aria2.conf</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
PLIST
```
*(Remember to replace `YOUR_USERNAME` with your Mac username, and adjust the aria2c path if you used Homebrew on Apple Silicon: `/opt/homebrew/bin/aria2c`).* Then load it:
```bash
launchctl load ~/Library/LaunchAgents/com.aria2.daemon.plist
```

---

## Step 3: Install the Browser Extension

Now that the engine is running in the background, connect your browser to it:

1. **Chromium (Chrome / Edge / Brave):** Install [Aria2 for Chrome](https://chrome.google.com/webstore/detail/aria2-for-chrome/mpkodccbngfoacfalldjimigbofkhgjn)
2. **Firefox:** Install [Aria2 Integration](https://addons.mozilla.org/en-US/firefox/addon/aria2-integration/)

### Extension Setup:

1. **Right-click** the extension icon in your browser toolbar and select **Options / Settings**.
2. Tap the **`+` (Add)** button to create a new connection profile.
3. Fill out the details:
   * **Name:** Net-Booster (or anything you like)
   * **Host:** `localhost`
   * **Port:** `6800`
   * **Secret:** *(Leave completely blank)*
4. **CRITICAL SPEED FIX:** Scroll down to the **RPC Parameters** box. By default, the extension will put `split: 5` in this box. **You must delete this so the box is empty!** If you don't delete it, the extension will override our 16-connection speed boost and bottleneck you down to 5.
5. Click **Save**.
6. Finally, click the extension icon in your toolbar and toggle it to **"Auto-Capture"** mode (usually a large switch).

**🎉 Done!** Every file you download in your browser will now automatically route through Net-Booster at maximum speed.
