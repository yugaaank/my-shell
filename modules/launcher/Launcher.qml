pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.services

// Windows 11 Start menu: search-first, pinned grid, recommended recents.
// Bottom-center flyout above the taskbar with 8px radius and taskbar-grade
// acrylic. Motion per Fluent tokens: slide-up + fade in on invoke (250ms),
// slide-down + fade on dismiss (167ms) — taskbar flyouts behave identically.
// Search pattern from ii AppSearch.qml:44; icons via Windows.guessIcon.
// ponytail: no usage-ranked recommendations (session recents only), no
// folders/groups; right-click pins, middle-click does nothing.
PanelWindow {
    id: root

    required property bool open
    signal dismissed()

    screen: Quickshell.screens.find(s => s.name === Hypr.focusedMonitor?.name) ?? Quickshell.screens[0]

    anchors {
        bottom: true
    }
    margins {
        bottom: 68
    }
    implicitWidth: 600
    implicitHeight: 560
    color: "transparent"

    // Rounded Start body: the window itself stays rectangular (layer-shell
    // has no radius); transparency + inner rect = Win11 rounded flyout.
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

    // Exit choreography: hide only after the dismiss slide finishes.
    property bool shown: false
    property bool leaving: false

    visible: shown

    onOpenChanged: {
        if (open) {
            leaving = false;
            shown = true;
            showAll = false;
            query.text = "";
            query.forceActiveFocus();
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

    property bool showAll: false
    readonly property bool searching: query.text.length > 0
    readonly property var matches: Array.from(DesktopEntries.applications.values).filter(a => !a.noDisplay && a.name.toLowerCase().includes(query.text.toLowerCase())).slice(0, 30)

    function launch(entry: var): void {
        Pins.noteLaunch(entry);
        entry.execute();
        root.dismissed();
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.open === true
        onActivated: root.dismissed()
    }

    // Flyout motion: up + in on invoke, down + out on dismiss.
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
            anchors.margins: 16
            spacing: 10

            TextField {
                id: query

                Layout.fillWidth: true
                placeholderText: "Type here to search"
                onAccepted: {
                    if (root.matches.length > 0)
                        root.launch(root.matches[0]);
                }
            }

            // Search results replace the pinned/recommended body.
            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                visible: root.searching
                model: ScriptModel {
                    values: root.matches ?? []
                }

                delegate: ItemDelegate {
                    required property var modelData

                    width: ListView.view.width
                    text: modelData.name
                    onClicked: root.launch(modelData)
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8
                visible: !root.searching

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: root.showAll ? "All apps" : "Pinned"
                        color: "#cdd6f4"
                        font.pixelSize: 14
                        font.bold: true
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Button {
                        text: root.showAll ? "‹ Back" : "All apps ›"
                        onClicked: root.showAll = !root.showAll
                    }
                }

                GridView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    cellWidth: 88
                    cellHeight: 92
                    model: ScriptModel {
                        values: root.showAll ? Array.from(DesktopEntries.applications.values).filter(a => !a.noDisplay) : Pins.resolved(Pins.pinned)
                    }

                    delegate: AppCell {
                        entry: modelData ?? null
                    }
                }

                Text {
                    visible: !root.showAll
                    text: "Recommended"
                    color: "#cdd6f4"
                    font.pixelSize: 14
                    font.bold: true
                }

                ListView {
                    Layout.fillWidth: true
                    implicitHeight: 64
                    visible: !root.showAll
                    clip: true
                    orientation: ListView.Horizontal
                    spacing: 4
                    model: ScriptModel {
                        values: Pins.resolved(Pins.recent)
                    }

                    delegate: AppCell {
                        entry: modelData
                        compact: true
                    }
                }
            }
        }
    }

    component AppCell: Item {
        id: cell

        property var entry
        property bool compact: false

        implicitWidth: cell.compact ? 160 : 88
        implicitHeight: cell.compact ? 64 : 92

        readonly property string iconName: entry ? Windows.guessIcon(entry.appId ?? entry.id) : ""

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 2

            IconImage {
                Layout.alignment: Qt.AlignHCenter
                implicitSize: cell.compact ? 28 : 40
                visible: cell.iconName !== ""
                source: visible ? Quickshell.iconPath(cell.iconName, "") : ""
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                visible: cell.iconName === ""
                text: (cell.entry?.name ?? "?").charAt(0).toUpperCase()
                color: "#cdd6f4"
                font.pixelSize: 22
                font.bold: true
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                maximumLineCount: cell.compact ? 1 : 2
                wrapMode: Text.Wrap
                color: "#cdd6f4"
                font.pixelSize: 12
                text: cell.entry?.name ?? ""
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: event => {
                if (!cell.entry)
                    return;
                if (event.button === Qt.RightButton)
                    Pins.togglePin(cell.entry.id);
                else
                    root.launch(cell.entry);
            }
        }
    }
}
