pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia

// Architecture:
//   - daemonProc: long-running "hyprsunset -t <K>" process that holds gamma control
//   - ipcProc:    short-lived "hyprctl hyprsunset temperature <K>" for LIVE updates
//
// When temperature changes while active, we send via IPC (no restart → no flicker).
// The daemon is only restarted when toggling on/off.
Singleton {
    id: root

    readonly property alias temperature: props.temperature
    readonly property alias active: props.active
    property bool available: true

    property int _pending: -1  // queued temperature for when ipcProc is busy

    function start(temp): void {
        if (temp !== undefined && temp !== null)
            props.temperature = temp;
        props.active = true;
        if (daemonProc.running) {
            // Daemon already up — just update temperature via IPC (no flicker)
            _sendIpc(props.temperature);
        } else {
            // Start daemon with correct temperature baked in
            daemonProc.command = ["hyprsunset", "-t", props.temperature.toString()];
            daemonProc.running = true;
        }
    }

    function stop(): void {
        props.active = false;
        _pending = -1;
        ipcProc.running = false;
        daemonProc.running = false;  // killing daemon resets gamma to identity automatically
    }

    function toggle(temp): void {
        if (props.active)
            stop();
        else
            start(temp);
    }

    // IPC: queue-based so we never miss the latest value during rapid slider moves
    function _sendIpc(temp: int): void {
        if (ipcProc.running) {
            _pending = temp;   // hyprctl busy → overwrite pending (only latest matters)
        } else {
            _pending = -1;
            ipcProc.command = ["hyprctl", "hyprsunset", "temperature", temp.toString()];
            ipcProc.running = true;
        }
    }

    PersistentProperties {
        id: props

        property int temperature: 6000
        property bool active: false

        reloadableId: "hyprSunset"
    }

    Component.onCompleted: {
        if (props.active) {
            daemonProc.command = ["hyprsunset", "-t", props.temperature.toString()];
            daemonProc.running = true;
        }
    }

    // Long-running daemon — holds gamma control for the session
    Process {
        id: daemonProc
        stdout: StdioCollector {}
        stderr: StdioCollector { id: daemonErr }

        onExited: code => { // qmllint disable signal-handler-parameters
            if (code !== 0 && props.active) {
                console.error("[HyprSunset] daemon crashed: " + daemonErr.text);
                props.active = false;
            }
        }
    }

    // Short-lived hyprctl IPC — updates temperature without restarting daemon
    Process {
        id: ipcProc
        stdout: StdioCollector {}
        stderr: StdioCollector { id: ipcErr }

        onExited: code => { // qmllint disable signal-handler-parameters
            if (code !== 0)
                console.error("[HyprSunset] IPC failed: " + ipcErr.text);

            // Flush queued temperature (latest value from rapid slider moves)
            if (root._pending >= 0) {
                const t = root._pending;
                root._pending = -1;
                ipcProc.command = ["hyprctl", "hyprsunset", "temperature", t.toString()];
                ipcProc.running = true;
            }
        }
    }
}
