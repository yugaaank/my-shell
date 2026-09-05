//@ pragma Env QS_NO_RELOAD_POPUP=1

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.background
import qs.modules.taskbar
import qs.modules.launcher
import qs.modules.notifs as NotifCenter

ShellRoot {
    id: root

    property bool launcherOpen: false
    property bool notifOpen: false

    Background {}
    // One taskbar per monitor. Variants injects modelData; Taskbar declares it.
    Variants {
        model: Quickshell.screens

        Taskbar {
            onToggleLauncher: root.launcherOpen = !root.launcherOpen
            onToggleNotifs: root.notifOpen = !root.notifOpen
        }
    }

    Launcher {
        open: root.launcherOpen
        onDismissed: root.launcherOpen = false
    }

    NotifCenter.Notifs {
        open: root.notifOpen
        onDismissed: root.notifOpen = false
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
}
