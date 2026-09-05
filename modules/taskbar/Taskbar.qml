pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.services

// Fluent-styled taskbar (see MICROSOFT_UI_REFERENCE.md). Win11 taskbar is
// edge-flush chrome, so no corner radius here — radii belong to popups.
// Mica ≈ opaque wallpaper-neutral fill + 1px top light-edge (real tint needs
// a wallpaper-color probe; see reference §2). Motion uses exact Fluent tokens:
// direct entrance cubic-bezier(0,0,0,1) @250ms, press feedback @167ms.
PanelWindow {
    id: root

    required property ShellScreen modelData
    screen: modelData

    signal toggleLauncher()
    signal toggleNotifs()
    signal toggleQuick()

    anchors {
        bottom: true
        left: true
        right: true
    }
    exclusiveZone: 56
    implicitHeight: 56
    // Win11 dark taskbar: neutral grey acrylic, not blue-black. Translucency
    // + Hyprland blur rule (hypr/blur.conf) = frosted glass; opaque content
    // stays crisp because blur only shows through translucent pixels.
    color: "#b32b2b2b"

    // Fluent "light" pillar: 1px top edge highlight.
    Rectangle {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: 1
        color: "#ffffff"
        opacity: 0.08
    }
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 10
        spacing: 4

        // Balance spacer: centers the launcher + window cluster Win11-style.
        Item {
            Layout.fillWidth: true
        }

        // Launcher button
        Text {
            text: "☰"
            color: "#cdd6f4"
            font.pixelSize: 20
            scale: launchArea.pressed ? 0.85 : 1.0

            Behavior on scale {
                NumberAnimation {
                    duration: 167
                    easing.type: Easing.Bezier
                    easing.bezierCurve: [0, 0, 0, 1]
                }
            }

            MouseArea {
                id: launchArea
                anchors.fill: parent
                onClicked: root.toggleLauncher()
            }
        }

        // Window groups
        Repeater {
            model: ScriptModel {
                values: Windows.groups ?? []
            }

            delegate: Item {
                required property var modelData

                implicitWidth: 44
                implicitHeight: 44

                // Press physics + entrance (direct entrance token).
                scale: pressArea.pressed ? 0.85 : 1.0
                opacity: 0

                Component.onCompleted: opacity = 1

                Behavior on scale {
                    NumberAnimation {
                        duration: 167
                        easing.type: Easing.Bezier
                        easing.bezierCurve: [0, 0, 0, 1]
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.Bezier
                        easing.bezierCurve: [0, 0, 0, 1]
                    }
                }

                readonly property string iconName: Windows.guessIcon(modelData.appId)

                IconImage {
                    anchors.centerIn: parent
                    implicitSize: 32
                    visible: parent.iconName !== ""
                    source: visible ? Quickshell.iconPath(parent.iconName, "") : ""
                }

                Text {
                    anchors.centerIn: parent
                    visible: parent.iconName === ""
                    text: modelData.appId.charAt(0).toUpperCase()
                    color: "#cdd6f4"
                    font.pixelSize: 20
                    font.bold: true
                }

                // Running indicator: fade per gentle-exit pacing.
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    implicitWidth: 20
                    implicitHeight: 3
                    radius: 2
                    color: "#89b4fa"
                    opacity: Windows.isActive(modelData) ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 167
                            easing.type: Easing.Bezier
                            easing.bezierCurve: [1, 0, 1, 1]
                        }
                    }
                }

                // Extra-window dots
                Row {
                    spacing: 2
                    anchors.top: parent.top
                    anchors.topMargin: 2
                    anchors.horizontalCenter: parent.horizontalCenter

                    Repeater {
                        model: Math.min(modelData.toplevels.length - 1, 3)

                        Rectangle {
                            implicitWidth: 4
                            implicitHeight: 4
                            radius: 2
                            color: "#6c7086"
                        }
                    }
                }

                MouseArea {
                    id: pressArea
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    onClicked: event => {
                        if (event.button === Qt.MiddleButton)
                            Windows.closeFront(modelData);
                        else
                            Windows.cycleActivate(modelData);
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
        }

        Text {
            color: Audio.muted ? "#f38ba8" : "#a6e3a1"
            text: Math.round(Audio.volume * 100) + "%"

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                onClicked: event => {
                    if (event.button === Qt.MiddleButton)
                        Audio.toggleMute();
                    else
                        root.toggleQuick();
                }
                onWheel: event => {
                    if (event.angleDelta.y > 0)
                        Audio.incrementVolume();
                    else if (event.angleDelta.y < 0)
                        Audio.decrementVolume();
                }
            }
        }

        Item {
            implicitWidth: clockRow.implicitWidth
            implicitHeight: clockRow.implicitHeight

            RowLayout {
                id: clockRow
                spacing: 6

                // Win11 bell badge: unread dot beside the clock.
                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: 8
                    implicitHeight: 8
                    radius: 4
                    color: "#89b4fa"
                    visible: Notifs.unread > 0
                }

                Text {
                    color: "#cdd6f4"
                    text: Qt.formatDateTime(clock.date, "HH:mm")

                    SystemClock {
                        id: clock
                        precision: SystemClock.Minutes
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.toggleNotifs()
            }
        }
    }
}
