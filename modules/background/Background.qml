pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Per-screen background layer with crossfade. Simplified caelestia
// modules/background/Wallpaper.qml: two stacked async images, the freshly
// loaded one fades in on top; no CachingImage component needed.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win

        required property ShellScreen modelData
        screen: modelData

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        WlrLayershell.layer: WlrLayer.Background
        color: "black"

        property string want: Wallpapers.current
        property Image top: imgA

        onWantChanged: {
            if (!want)
                return;
            const next = (top === imgA) ? imgB : imgA;
            next.source = `file://${want}`;
        }

        component XImage: Image {
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            opacity: win.top === this ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 400
                }
            }

            onStatusChanged: {
                if (status === Image.Ready && source.toString() === `file://${win.want}`)
                    win.top = this;
            }
        }

        XImage {
            id: imgA
        }

        XImage {
            id: imgB
        }

        Component.onCompleted: {
            if (win.want)
                imgA.source = `file://${win.want}`;
        }
    }
}
