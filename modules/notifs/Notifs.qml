pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services

// Clock flyout + notification center (Win+N): calendar on top, app-grouped
// history below, Clear all + DND row. Bottom-right above the taskbar, same
// acrylic recipe as Start. Same open/exit choreography as Launcher.
// ponytail: no agenda integration, no per-notification actions row yet
// (buttons exist on the record — wire them when popups land).
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
    implicitWidth: 380
    implicitHeight: 540
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
            Notifs.markRead();
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
            spacing: 8

            // Date header + controls
            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: Qt.formatDateTime(new Date(), "d MMMM yyyy")
                        color: "#cdd6f4"
                        font.pixelSize: 16
                        font.bold: true
                    }

                    Text {
                        text: Qt.formatDateTime(new Date(), "dddd")
                        color: "#a6adc8"
                        font.pixelSize: 12
                    }
                }

                Button {
                    text: Notifs.dnd ? "DND on" : "DND"
                    onClicked: Notifs.toggleDnd()
                }

                Button {
                    text: "Clear all"
                    enabled: Notifs.list.length > 0
                    onClicked: Notifs.clearAll()
                }
            }

            // Calendar
            DayOfWeekRow {
                Layout.fillWidth: true
                locale: Qt.locale()
            }

            MonthGrid {
                Layout.fillWidth: true
                implicitHeight: 200
                locale: Qt.locale()
                month: new Date().getMonth()
                year: new Date().getFullYear()

                delegate: Text {
                    required property var modelData

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    opacity: modelData.month === parent.month ? 1 : 0.35
                    color: "#cdd6f4"
                    font.pixelSize: 12
                    font.bold: modelData.today
                    text: modelData.day

                    Rectangle {
                        anchors.centerIn: parent
                        implicitWidth: 24
                        implicitHeight: 24
                        radius: 12
                        color: "transparent"
                        border.color: "#89b4fa"
                        border.width: modelData.today ? 1 : 0
                        z: -1
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: "#ffffff"
                opacity: 0.08
            }

            // Grouped history
            Text {
                visible: Notifs.list.length === 0
                text: Notifs.dnd ? "Do not disturb is on — new alerts stay silent" : "No new notifications"
                color: "#6c7086"
                font.pixelSize: 13
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 8
                model: ScriptModel {
                    values: Notifs.groups ?? []
                }

                delegate: ColumnLayout {
                    required property var modelData

                    width: ListView.view.width
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            Layout.fillWidth: true
                            text: modelData.appName
                            color: "#a6adc8"
                            font.pixelSize: 12
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Button {
                            text: "Clear"
                            onClicked: Notifs.clearApp(modelData.appName)
                        }
                    }

                    Repeater {
                        model: ScriptModel {
                            values: modelData.items ?? []
                        }

                        delegate: Rectangle {
                            required property var modelData

                            implicitWidth: parent.width
                            implicitHeight: bodyCol.implicitHeight + 16
                            radius: 6
                            color: "#22ffffff"

                            ColumnLayout {
                                id: bodyCol

                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 2

                                RowLayout {
                                    Layout.fillWidth: true

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.summary || "(no title)"
                                        color: "#cdd6f4"
                                        font.pixelSize: 13
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: "✕"
                                        color: "#6c7086"
                                        font.pixelSize: 13

                                        MouseArea {
                                            anchors.fill: parent
                                            anchors.margins: -6
                                            onClicked: Notifs.dismiss(modelData.notificationId)
                                        }
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    visible: text.length > 0
                                    text: modelData.body
                                    color: "#a6adc8"
                                    font.pixelSize: 12
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 4
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: modelData.time
                                    color: "#6c7086"
                                    font.pixelSize: 11
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
