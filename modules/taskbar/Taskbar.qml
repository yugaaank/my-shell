pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.services

// Bottom taskbar replacing the top bar. Window buttons group by appId
// (services/Windows.qml, ii TaskbarApps pattern); click cycles + activates
// (ii DockAppButton.qml:64-71), middle-click closes the front window.
// ponytail: no pins, no hover previews, icon = raw appId; add
// heuristicLookup/guessIcon + ScreencopyView preview (ii DockApps.qml:63-227) when missed.
PanelWindow {
    id: root

    required property ShellScreen modelData
    screen: modelData

    signal toggleLauncher()

    anchors {
        bottom: true
        left: true
        right: true
    }
    exclusiveZone: 56
    implicitHeight: 56
    color: "#cc1a1a2e"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 10
        spacing: 4

        // Launcher button
        Text {
            text: "☰"
            color: "#cdd6f4"
            font.pixelSize: 20

            MouseArea {
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

                // Active underline
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    implicitWidth: 20
                    implicitHeight: 3
                    radius: 2
                    visible: Windows.isActive(modelData)
                    color: "#89b4fa"
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
                onClicked: Audio.toggleMute()
                onWheel: event => {
                    if (event.angleDelta.y > 0)
                        Audio.incrementVolume();
                    else if (event.angleDelta.y < 0)
                        Audio.decrementVolume();
                }
            }
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
}
