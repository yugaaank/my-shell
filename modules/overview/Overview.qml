pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services

// Exposé spread for the focused workspace (ii overview, uniform grid v1):
// live previews, click focuses, middle-click closes, Esc dismisses.
// Fullscreen transparent window over a dim layer; nothing behind is clickable.
// ponytail: uniform cells, not spatial mapping (OverviewWindow initX/initY);
// no drag-to-workspace (TaskViewContent DragHandler) yet.
PanelWindow {
    id: root

    required property bool open
    signal dismissed()

    screen: Quickshell.screens.find(s => s.name === Hypr.focusedMonitor?.name) ?? Quickshell.screens[0]

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    visible: open

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    // Dim backdrop; click-through empty area dismisses.
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.55

        MouseArea {
            anchors.fill: parent
            onClicked: root.dismissed()
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.open === true
        onActivated: root.dismissed()
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width - 120, 1100)
        spacing: 12

        Text {
            Layout.alignment: Qt.AlignHCenter
            visible: Windows.wsToplevels.length === 0
            text: "No windows on this workspace"
            color: "#a6adc8"
            font.pixelSize: 15
        }

        GridView {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: Math.min(contentWidth, parent.width)
            implicitHeight: Math.min(contentHeight, parent.height - 60)
            clip: true
            cellWidth: 344
            cellHeight: 252
            model: ScriptModel {
                values: Windows.wsToplevels ?? []
            }

            delegate: ColumnLayout {
                required property var modelData

                width: 344
                spacing: 4

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 328
                    implicitHeight: 208
                    radius: 8
                    color: "#d62b2b2b"
                    border.color: modelData.activated ? "#89b4fa" : "#1affffff"
                    border.width: modelData.activated ? 2 : 1

                    ScreencopyView {
                        anchors.fill: parent
                        anchors.margins: 1
                        captureSource: modelData
                        live: true
                        constraintSize: Qt.size(328, 208)
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        hoverEnabled: true
                        onClicked: event => {
                            if (event.button === Qt.MiddleButton)
                                modelData.close();
                            else {
                                modelData.activate();
                                root.dismissed();
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideMiddle
                    color: "#cdd6f4"
                    font.pixelSize: 12
                    text: modelData.title || modelData.appId
                }
            }
        }
    }
}
