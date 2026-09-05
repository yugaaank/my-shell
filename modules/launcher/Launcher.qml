pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services

// Centered app launcher. Toggle via `qs ipc call launcher toggle`.
// Search pattern from ii/services/AppSearch.qml:44-49
// (DesktopEntries.applications.values → list<DesktopEntry>).
// ponytail: text rows only, no icons/fuzzy; add Fuzzy.go + IconImage when plain filter hurts.
PanelWindow {
    required property bool open
    signal dismissed()

    visible: open
    screen: Quickshell.screens.find(s => s.name === Hypr.focusedMonitor?.name) ?? Quickshell.screens[0]

    anchors {
        top: true
    }
    margins {
        top: 180
    }
    implicitWidth: 560
    implicitHeight: 380
    color: "#ee11111b"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    onOpenChanged: {
        if (open) {
            query.text = "";
            query.forceActiveFocus();
        }
    }

    readonly property var matches: Array.from(DesktopEntries.applications.values).filter(a => !a.noDisplay && a.name.toLowerCase().includes(query.text.toLowerCase())).slice(0, 20)

    function launch(entry: DesktopEntry): void {
        entry.execute();
        root.dismissed();
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.open === true
        onActivated: root.dismissed()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        TextField {
            id: query

            Layout.fillWidth: true
            placeholderText: "Type to search…"
            onAccepted: {
                if (root.matches.length > 0)
                    root.launch(root.matches[0]);
            }
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: ScriptModel {
                values: root.matches ?? []
            }

            delegate: ItemDelegate {
                required property DesktopEntry modelData

                width: ListView.view.width
                text: modelData.name
                onClicked: root.launch(modelData)
            }
        }
    }
}
