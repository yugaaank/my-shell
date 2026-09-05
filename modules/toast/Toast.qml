pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services

// Toast popup: newest notification, bottom-right above the taskbar, 5s
// auto-expire (service timer). Click opens the center. Slide-up + fade per
// Fluent flyout tokens; hidden while the center is open to avoid overlap.
PanelWindow {
    id: root

    required property ShellScreen modelData
    screen: modelData

    property bool centerOpen: false
    signal toastOpened()

        anchors {
            bottom: true
            right: true
        }
        margins {
            bottom: 68
            right: 8
        }
        implicitWidth: 360
        implicitHeight: 96
        color: "transparent"

        visible: Notifs.toastVisible && !centerOpen

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: "#d62b2b2b"
            border.color: "#1affffff"
            border.width: 1
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusionMode: ExclusionMode.Ignore

        Item {
            anchors.fill: parent
            y: root.visible ? 0 : 16
            opacity: root.visible ? 1 : 0

        Behavior on y {
            NumberAnimation {
                duration: 250
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

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: `${Notifs.toastItem?.appName ?? ""}`
                color: "#a6adc8"
                font.pixelSize: 11
                font.bold: true
                elide: Text.ElideRight
                visible: text.length > 0
            }

            Text {
                Layout.fillWidth: true
                text: Notifs.toastItem?.summary ?? ""
                color: "#cdd6f4"
                font.pixelSize: 13
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: text.length > 0
                text: Notifs.toastItem?.body ?? ""
                color: "#a6adc8"
                font.pixelSize: 12
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.Wrap
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                Notifs.hideToast();
                root.toastOpened();
            }
        }
        }
}
