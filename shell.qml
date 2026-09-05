//@ pragma Env QS_NO_RELOAD_POPUP=1

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.taskbar
import qs.modules.launcher

ShellRoot {
    id: root

    property bool launcherOpen: false

    // One taskbar per monitor. Variants injects modelData; Taskbar declares it.
    Variants {
        model: Quickshell.screens

        Taskbar {
            onToggleLauncher: root.launcherOpen = !root.launcherOpen
        }
    }

    Launcher {
        open: root.launcherOpen
        onDismissed: root.launcherOpen = false
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
}
