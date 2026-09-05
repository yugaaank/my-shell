pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services

// Quick Settings (Win+A): radios, DND, sliders. Bottom-right acrylic flyout,
// same chrome + open/exit motion as Start and the clock center.
// ponytail: no wifi network list (tile toggles radio; picker is follow-up),
// no media block (MPRIS next), brightness slider hides without brightnessctl.
PanelWindow {
    id: root

    required property bool open
    signal dismissed()

    screen: Quickshell.screens.find(s => s.name === Hypr.focusedMonitor?.name) ?? Quickshell.screens[0]

    anchors {
        bottom: true
        right: true
    }
    margins {
        bottom: 68
        right: 8
    }
    implicitWidth: 340
    implicitHeight: 380
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: "#d62b2b2b"
        border.color: "#1affffff"
        border.width: 1
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    property bool shown: false
    property bool leaving: false

    visible: shown

    onOpenChanged: {
        if (open) {
            leaving = false;
            shown = true;
            Devices.refresh();
        } else if (shown) {
            leaving = true;
            leaveTimer.restart();
        }
    }

    Timer {
        id: leaveTimer
        interval: 180
        onTriggered: {
            root.shown = false;
            root.leaving = false;
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.open === true
        onActivated: root.dismissed()
    }

    Item {
        anchors.fill: parent
        y: (root.shown && !root.leaving) ? 0 : 20
        opacity: (root.shown && !root.leaving) ? 1 : 0

        Behavior on y {
            NumberAnimation {
                duration: root.leaving ? 167 : 250
                easing.type: Easing.Bezier
                easing.bezierCurve: [0, 0, 0, 1]
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: root.leaving ? 167 : 250
                easing.type: Easing.Bezier
                easing.bezierCurve: [0, 0, 0, 1]
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 8
                columnSpacing: 8

                Tile {
                    active: Devices.wifiEnabled
                    title: "Wi-Fi"
                    sub: Devices.wifiEnabled ? (Devices.wifiSsid || "On") : "Off"
                    onClicked: Devices.toggleWifi()
                }

                Tile {
                    active: Devices.btPowered
                    title: "Bluetooth"
                    sub: Devices.btPowered ? "On" : "Off"
                    onClicked: Devices.toggleBt()
                }

                Tile {
                    active: Notifs.dnd
                    title: "Do not disturb"
                    sub: Notifs.dnd ? "On" : "Off"
                    onClicked: Notifs.toggleDnd()
                }

                Tile {
                    active: !Audio.muted
                    title: "Mute"
                    sub: Audio.muted ? "Muted" : `${Math.round(Audio.volume * 100)}%`
                    onClicked: Audio.toggleMute()
                }
            }

            Text {
                visible: Devices.batteryAvailable
                text: `🔋 ${Math.round(Devices.batteryPct * 100)}%${Devices.batteryCharging ? " — charging" : ""}`
                color: "#cdd6f4"
                font.pixelSize: 13
            }

            // Volume
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "🔈"
                    font.pixelSize: 16
                }

                Slider {
                    Layout.fillWidth: true
                    from: 0
                    to: 1
                    value: Audio.volume
                    onMoved: Audio.setVolume(value)
                }

                Text {
                    text: `${Math.round(Audio.volume * 100)}%`
                    color: "#a6adc8"
                    font.pixelSize: 12
                }
            }

            // Brightness
            RowLayout {
                Layout.fillWidth: true
                visible: Devices.hasBacklight
                spacing: 8

                Text {
                    text: "🔆"
                    font.pixelSize: 16
                }

                Slider {
                    Layout.fillWidth: true
                    from: 0.05
                    to: 1
                    value: Devices.brightness
                    onMoved: Devices.setBrightness(value)
                }

                Text {
                    text: `${Math.round(Devices.brightness * 100)}%`
                    color: "#a6adc8"
                    font.pixelSize: 12
                }
            }
        }
    }

    component Tile: Rectangle {
        id: tile

        required property bool active
        required property string title
        required property string sub
        signal clicked()

        Layout.fillWidth: true
        implicitHeight: 64
        radius: 8
        color: tile.active ? "#4089b4fa" : "#22ffffff"
        scale: tileArea.pressed ? 0.96 : 1.0

        Behavior on scale {
            NumberAnimation {
                duration: 167
                easing.type: Easing.Bezier
                easing.bezierCurve: [0, 0, 0, 1]
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: 167
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 0

            Text {
                text: tile.title
                color: "#cdd6f4"
                font.pixelSize: 13
                font.bold: true
            }

            Text {
                text: tile.sub
                color: "#a6adc8"
                font.pixelSize: 12
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: tileArea
            anchors.fill: parent
            onClicked: tile.clicked()
        }
    }
}
