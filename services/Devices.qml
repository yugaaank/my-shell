pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

// Radios + power in one place (ponytail: single file, poll-based).
// nmcli/bluetoothctl polling collapses to one bash probe (ii Network.qml
// fans out to 6 processes; one is enough at 5s cadence). Brightness via
// brightnessctl (ii Brightness.qml:157-167), battery via UPower display
// device (ii Battery.qml:12-16).
Singleton {
    id: root

    // WiFi / Bluetooth (polled)
    property bool wifiEnabled: false
    property string wifiSsid: ""
    property bool btPowered: false

    // Backlight 0..1 (brightnessctl class backlight; 0 floor avoids black)
    property real brightness: 1.0
    property bool hasBacklight: false

    // Battery (UPower, live bindings)
    readonly property bool batteryAvailable: UPower.displayDevice.isLaptopBattery
    readonly property real batteryPct: UPower.displayDevice?.percentage ?? 1
    readonly property bool batteryCharging: UPower.displayDevice?.state === UPowerDeviceState.Charging

    function toggleWifi(): void {
        setProc.exec(["nmcli", "radio", "wifi", root.wifiEnabled ? "off" : "on"]);
    }

    function toggleBt(): void {
        setProc.exec(["bluetoothctl", "power", root.btPowered ? "off" : "on"]);
    }

    function setBrightness(v: real): void {
        v = Math.max(0.05, Math.min(1, v));
        root.brightness = v;
        setProc.exec(["brightnessctl", "--class", "backlight", "s", `${Math.round(v * 100)}%`, "--quiet"]);
    }

    function refresh(): void {
        pollProc.running = true;
    }

    Component.onCompleted: root.refresh()

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Process {
        id: setProc
    }

    Process {
        id: pollProc

        command: ["bash", "-c", "echo WIFI=$(nmcli -t -f WIFI general 2>/dev/null); echo SSID=$(nmcli -t -f NAME connection show --active 2>/dev/null | head -1); echo BT=$(bluetoothctl show 2>/dev/null | grep -m1 'Powered:' | awk '{print $2}'); echo BL=$(brightnessctl --class backlight get 2>/dev/null); echo BLMAX=$(brightnessctl --class backlight max 2>/dev/null)"]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.trim().split("\n")) {
                    const eq = line.indexOf("=");
                    if (eq === -1)
                        continue;
                    const k = line.slice(0, eq), v = line.slice(eq + 1);
                    if (k === "WIFI")
                        root.wifiEnabled = v.trim() === "enabled";
                    else if (k === "SSID")
                        root.wifiSsid = v.trim();
                    else if (k === "BT")
                        root.btPowered = v.trim() === "yes";
                    else if (k === "BL" || k === "BLMAX")
                        root._bl[k] = parseInt(v) || 0;
                }
                if ((root._bl.BLMAX || 0) > 0) {
                    root.hasBacklight = true;
                    root.brightness = Math.max(0.05, Math.min(1, root._bl.BL / root._bl.BLMAX));
                } else {
                    root.hasBacklight = false;
                }
            }
        }
    }

    property var _bl: ({})
}
