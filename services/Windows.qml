pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland

// Window grouping in the ii style (TaskbarApps.qml:23-60): group the
// compositor-agnostic ToplevelManager.toplevels by appId. No pins, no
// separator — those need a Config/Persistent store; add with it.
// Click behavior mirrors DockAppButton.qml:64-71 (cycle + activate).
Singleton {
    id: root

    // Array of {appId, toplevels[]} plain objects.
    readonly property var groups: {
        const map = new Map();
        for (const t of ToplevelManager.toplevels.values) {
            if (!t.appId)
                continue;
            const key = t.appId.toLowerCase();
            if (!map.has(key))
                map.set(key, {
                    appId: t.appId,
                    toplevels: []
                });
            map.get(key).toplevels.push(t);
        }
        return Array.from(map.values());
    }

    property var lastIdx: ({})

    function cycleActivate(entry: var): void {
        const ts = entry.toplevels ?? [];
        if (ts.length === 0)
            return;
        const next = ((root.lastIdx[entry.appId] ?? -1) + 1) % ts.length;
        root.lastIdx[entry.appId] = next;
        ts[next].activate();
    }

    function closeFront(entry: var): void {
        const ts = entry.toplevels ?? [];
        const target = ts.find(t => t.activated) ?? ts[0];
        if (target)
            target.close();
    }

    function isActive(entry: var): bool {
        return (entry.toplevels ?? []).some(t => t.activated);
    }

    // ii AppSearch.qml:80-83 pattern: probe the theme, never guess blind.
    function iconExists(name: string): bool {
        return !!name && Quickshell.iconPath(name, true).length > 0;
    }

    // ii AppSearch substitutions + DockAppButton heuristicLookup, trimmed.
    function guessIcon(appId: string): string {
        const steam = appId.match(/^steam_app_(\d+)$/);
        if (steam) {
            if (iconExists(`steam_icon_${steam[1]}`))
                return `steam_icon_${steam[1]}`;
            if (iconExists("steam"))
                return "steam";
        }
        for (const cand of [appId, appId.toLowerCase()]) {
            if (iconExists(cand))
                return cand;
        }
        const entry = DesktopEntries.heuristicLookup(appId);
        if (entry?.icon && iconExists(entry.icon))
            return entry.icon;
        return "";
    }
}
