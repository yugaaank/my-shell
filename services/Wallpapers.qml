pragma Singleton

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io

// Lightest of the four: self-drawn background (no hyprpaper/swww daemon,
// no caelestia CLI, no thumbnail venv). Directory scan via Qt FolderListModel
// (ii services/Wallpapers.qml:116-133), current-path state file via FileView
// (caelestia services/Wallpapers.qml:85-104), IPC get/set/list/random.
// ponytail: no thumbnails, no transitions beyond crossfade, no per-monitor
// paths; add with a selector UI (Ax 629-line thumbs / noctalia transitions).
Singleton {
    id: root

    readonly property string dir: `${Quickshell.env("HOME")}/Pictures/Wallpapers`
    readonly property string stateFile: `${Quickshell.env("HOME")}/.cache/my-shell/wallpaper.txt`

    property string current: ""
    readonly property var all: {
        const out = [];
        for (let i = 0; i < files.count; i++) {
            const p = files.get(i, "filePath");
            if (p)
                out.push(p);
        }
        return out;
    }

    function setWallpaper(path: string): void {
        if (!path)
            return;
        root.current = path;
        Quickshell.execDetached(["bash", "-c", `mkdir -p "$(dirname "${root.stateFile}")" && printf '%s' "${path}" > "${root.stateFile}"`]);
    }

    function setRandom(): void {
        if (root.all.length === 0)
            return;
        root.setWallpaper(root.all[Math.floor(Math.random() * root.all.length)]);
    }

    FolderListModel {
        id: files

        folder: `file://${root.dir}`
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.avif", "*.bmp"]
        showDirs: false
        sortField: FolderListModel.Name
        onCountChanged: {
            if (!root.current && count > 0)
                root.current = get(0, "filePath") ?? "";
        }
    }

    // State file wins; else first image in dir.
    FileView {
        path: root.stateFile
        watchChanges: true
        printErrors: false
        onLoaded: {
            const wall = text().trim();
            root.current = wall || (root.all[0] ?? "");
        }
        onLoadFailed: {
            root.current = root.all[0] ?? "";
        }
        onFileChanged: reload()
    }

    IpcHandler {
        function get(): string {
            return root.current;
        }
        function set(path: string): void {
            root.setWallpaper(path);
        }
        function random(): void {
            root.setRandom();
        }
        function list(): string {
            return root.all.join("\n");
        }

        target: "wallpaper"
    }
}
