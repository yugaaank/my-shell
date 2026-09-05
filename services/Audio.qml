pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Trimmed from shell/services/Audio.qml. Cava/beatTracker/toasts dropped
// (need the Caelestia C++ plugin); add back when you build yours.
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool muted: !!sink?.audio?.muted
    readonly property real volume: sink?.audio?.volume ?? 0

    function setVolume(newVolume: real): void {
        if (sink?.ready && sink?.audio) {
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(1.0, newVolume));
        }
    }

    function incrementVolume(amount: real): void {
        setVolume(volume + (amount || 0.05));
    }

    function decrementVolume(amount: real): void {
        setVolume(volume - (amount || 0.05));
    }

    function toggleMute(): void {
        if (sink?.ready && sink?.audio)
            sink.audio.muted = !sink.audio.muted;
    }

    PwObjectTracker {
        objects: [root.sink].filter(n => n)
    }
}
