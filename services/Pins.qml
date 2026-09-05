pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Pinned + recently-launched apps for the Start menu. Pins persist in a
// newline text file (same state-file pattern as Wallpapers); recents are
// session-only. IDs are DesktopEntry ids, resolved by exact scan with
// heuristicLookup fallback (no byId API risk).
Singleton {
    id: root

    readonly property string stateFile: `${Quickshell.env("HOME")}/.cache/my-shell/pinned.txt`
    readonly property var seedIds: ["firefox", "org.mozilla.firefox", "code", "visual-studio-code", "kitty", "org.gnome.Nautilus", "thunar"]

    property var pinned: []
    property var recent: []
    property bool loaded: false

    function entryFor(id: string): var {
        return DesktopEntries.applications.values.find(e => e.id === id) ?? DesktopEntries.heuristicLookup(id) ?? null;
    }

    function resolved(ids: var): var {
        return ids.map(entryFor).filter(e => e);
    }

    function isPinned(id: string): bool {
        return root.pinned.includes(id);
    }

    function togglePin(id: string): void {
        root.pinned = root.isPinned(id) ? root.pinned.filter(p => p !== id) : root.pinned.concat([id]);
        persist();
    }

    function noteLaunch(entry: var): void {
        if (!entry?.id)
            return;
        root.recent = [entry.id].concat(root.recent.filter(r => r !== entry.id)).slice(0, 6);
    }

    function persist(): void {
        const body = root.pinned.length > 0 ? `printf '%s\\n' ${root.pinned.join(" ")}` : "printf ''";
        Quickshell.execDetached(["bash", "-c", `mkdir -p "$(dirname "${root.stateFile}")" && ${body} > "${root.stateFile}"`]);
    }

    FileView {
        path: root.stateFile
        watchChanges: true
        printErrors: false
        onLoaded: {
            const ids = text().split("\n").map(s => s.trim()).filter(s => s);
            root.pinned = ids.length > 0 ? ids : root.seedIds.filter(id => root.entryFor(id));
            root.loaded = true;
        }
        onLoadFailed: {
            root.pinned = root.seedIds.filter(id => root.entryFor(id));
            root.loaded = true;
        }
        onFileChanged: reload()
    }
}
