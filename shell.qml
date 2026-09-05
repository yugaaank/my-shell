//@ pragma Env QS_NO_RELOAD_POPUP=1

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.background
import qs.modules.taskbar
import qs.modules.launcher
import qs.modules.notifs as NotifCenter
import qs.modules.quick
import qs.modules.toast
import qs.modules.overview

ShellRoot {
    id: root

    property bool launcherOpen: false
    property bool notifOpen: false
    property bool quickOpen: false
    property bool overviewOpen: false

    Background {}
    // One taskbar per monitor. Variants injects modelData; Taskbar declares it.
    Variants {
        model: Quickshell.screens

        Taskbar {
            onToggleLauncher: root.launcherOpen = !root.launcherOpen
            onToggleNotifs: {
                root.notifOpen = !root.notifOpen;
                root.quickOpen = false;
            }
            onToggleQuick: {
                root.quickOpen = !root.quickOpen;
                root.notifOpen = false;
            }
        }
    }

    Variants {
        model: Quickshell.screens

        Toast {
            centerOpen: root.notifOpen
            onToastOpened: {
                root.notifOpen = true;
                root.quickOpen = false;
            }
        }
    }

    NotifCenter.Notifs {
        open: root.notifOpen
        onDismissed: root.notifOpen = false
    }

    Launcher {
        open: root.launcherOpen
        onDismissed: root.launcherOpen = false
    }

    Overview {
        open: root.overviewOpen
        onDismissed: root.overviewOpen = false
    }
    Quick {
        open: root.quickOpen
        onDismissed: root.quickOpen = false
    }

    IpcHandler {
        function toggle(): void {
            root.launcherOpen = !root.launcherOpen;
        }
        function open(): void {
            root.launcherOpen = true;
        }
        function close(): void {
            root.launcherOpen = false;
        }
        function isOpen(): string {
            return root.launcherOpen ? "1" : "0";
        }

        target: "launcher"
    }

    IpcHandler {
        function toggle(): void {
            root.notifOpen = !root.notifOpen;
        }
        function open(): void {
            root.notifOpen = true;
        }
        function close(): void {
            root.notifOpen = false;
        }
        function isOpen(): string {
            return root.notifOpen ? "1" : "0";
        }
        function clear(): void {
            Notifs.clearAll();
        }
        function toggleDnd(): void {
            Notifs.toggleDnd();
        }
        function count(): string {
            return `${Notifs.list.length}`;
        }
        function recent(): string {
            return Notifs.list.map(n => `${n.appName}: ${n.summary}`).join("\n");
        }

        target: "notifs"
    }

    IpcHandler {
        function toggle(): void {
            root.quickOpen = !root.quickOpen;
            root.notifOpen = false;
        }
        function open(): void {
            root.quickOpen = true;
            root.notifOpen = false;
        }
        function close(): void {
            root.quickOpen = false;
        }
        function isOpen(): string {
            return root.quickOpen ? "1" : "0";
        }

        target: "quick"
    }

    IpcHandler {
        function toggle(): void {
            root.overviewOpen = !root.overviewOpen;
        }
        function open(): void {
            root.launcherOpen = false;
            root.notifOpen = false;
            root.quickOpen = false;
            root.overviewOpen = true;
        }
        function close(): void {
            root.overviewOpen = false;
        }
        function isOpen(): string {
            return root.overviewOpen ? "1" : "0";
        }
        function count(): string {
            return `${Windows.wsToplevels.length}`;
        }
        function debug(): string {
            return `activeWs=${Windows.activeWsId}\n${Windows.wsDebug.join("\n")}`;
        }

        target: "overview"
    }
}
