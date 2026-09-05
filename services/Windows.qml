pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Window grouping in the ii style (TaskbarApps.qml:23-60): group the
// compositor-agnostic ToplevelManager.toplevels by appId. No pins, no
// separator — those need a Config/Persistent store; add with it.
// Click behavior mirrors DockAppButton.qml:64-71 (cycle + activate).
Singleton {
    id: root

    // Focused workspace straight from Hyprland (no sibling import — Windows
    // importing qs.services cycles back on itself and breaks resolution).
    readonly property var activeWsId: Hyprland.focusedWorkspace?.id ?? -1
    // Flat live windows on the focused workspace: workspace toplevels give
    // addresses, joined to ToplevelManager objects for previews (the attached
    // HyprlandToplevel has address but no workspace in qs 0.3.1).
    readonly property var wsToplevels: (Hyprland.focusedWorkspace?.toplevels.values ?? []).map(hl => ToplevelManager.toplevels.values.find(t => t.HyprlandToplevel?.address === hl.address)).filter(t => t)
    readonly property var wsDebug: ToplevelManager.toplevels.values.map(t => `${t.appId} hasHl=${!!t.HyprlandToplevel} attachedWs=${t.HyprlandToplevel?.workspace?.id} directWs=${Hyprland.focusedWorkspace?.id}`)
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
