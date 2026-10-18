pragma Singleton

import QtQuick
import Quickshell
import "compositors/Chords.js" as Chords
import "compositors/Contract.js" as Contract
import "compositors/Niri.js" as Niri
import "compositors/Umbriel.js" as Umbriel
import "compositors/Unset.js" as Unset

Singleton {
    id: root

    // The session's compositor: the one whose socket variable, which it
    // exports to its session, is set. Unset when none is or more than one is.
    readonly property var backends: ({
            NIRI_SOCKET: Niri,
            UMBRIEL_SOCKET: Umbriel
        })
    readonly property var configured: Object.keys(backends).sort().filter(key => Quickshell.env(key))
    readonly property var backend: configured.length === 1 ? backends[configured[0]] : Unset

    readonly property string name: backend.name
    // What differs between compositors; each backend says what each means.
    readonly property bool releaseExclusiveFocus: backend.releaseExclusiveFocus
    readonly property bool replacesDeadLock: backend.replacesDeadLock
    readonly property bool opensOnFocusedOutput: backend.opensOnFocusedOutput
    readonly property bool floatsInWorkingArea: backend.floatsInWorkingArea
    readonly property bool placesBackdrop: backend.placesBackdrop
    // Each optional feature of Contract.js, true when the backend has it; what
    // it lacks, the shell hides.
    readonly property var supports: Contract.supports(backend)
    // Components fed by events: with ids(output), activeId(output) and
    // occupied(idx, output); with sharing, true while a screencast runs; and
    // with windowId, the window of appId, kept round and on the focused
    // workspace. Empty when the backend has none.
    // Workspaces come from each backend, not Quickshell.WindowManager: its only
    // protocol, ext-workspace-v1, reports no windows, so no occupancy. It fits
    // once a protocol reports each window's workspace.
    readonly property url workspaceSource: backend.workspaceComponent ? Qt.resolvedUrl("compositors/" + backend.workspaceComponent) : ""
    readonly property url castSource: backend.castComponent ? Qt.resolvedUrl("compositors/" + backend.castComponent) : ""
    readonly property url pinSource: backend.pinComponent ? Qt.resolvedUrl("compositors/" + backend.pinComponent) : ""
    // The backend's one event stream, which only its own sources read, and one
    // of each source for the whole shell; null when the backend has none.
    readonly property var events: eventsLoader.item
    readonly property var workspaces: workspaceLoader.item
    readonly property var casts: castLoader.item

    property Loader eventsLoader: Loader {
        source: root.backend.eventsComponent ? Qt.resolvedUrl("compositors/" + root.backend.eventsComponent) : ""
    }
    property Loader workspaceLoader: Loader {
        source: root.workspaceSource
        onLoaded: item.events = Qt.binding(() => root.events) // qmllint disable missing-property
    }
    property Loader castLoader: Loader {
        source: root.castSource
        onLoaded: item.events = Qt.binding(() => root.events) // qmllint disable missing-property
    }
    // The file borderColors(palette) fills, under the shell's state dir.
    readonly property string borderFile: backend.borderFile || ""
    // The action closeWindow() runs, as a bind names it.
    readonly property string closeWindowAction: backend.closeWindowAction

    Component.onCompleted: {
        if (backend === Unset)
            console.error("no compositor:", configured.length ? "more than one is set: " + configured.join(", ") : "none of " + Object.keys(backends).sort().join(", ") + " is set");
    }

    function borderColors(palette) {
        return root.backend.borderColors(palette);
    }

    function dpms(on) {
        return root.backend.dpms(on);
    }
    function closeWindow() {
        return root.backend.closeWindow();
    }
    function screenshot(path) {
        return root.backend.screenshot(path);
    }
    function screenshotWindow(path) {
        return root.backend.screenshotWindow(path);
    }
    function pickColor() {
        return root.backend.pickColor();
    }
    // getenv(name) returns an environment variable.
    function configFile(home, getenv) {
        return root.backend.configFile(home, getenv);
    }
    function readBinds(file, home, read) {
        return root.backend.readBinds(file, home, read);
    }
    function keycaps(chord) {
        return Chords.keycaps(chord);
    }
    function focusWorkspace(id, output) {
        return root.backend.focusWorkspace(id, output);
    }
    function focusApp(pattern) {
        return root.backend.focusApp(pattern);
    }
    function focusMonitor(output) {
        return root.backend.focusMonitor(output);
    }
    function outputs() {
        return root.backend.outputs();
    }
    function focusedOutputOn(output) {
        return root.backend.focusedOutputOn(output);
    }
    function focusedMonitor(raw) {
        return root.backend.focusedMonitor(raw);
    }
    function moveFloatingWindow(id, x, y) {
        return root.backend.moveFloatingWindow(id, x, y);
    }
    function layoutQuery() {
        return root.backend.layoutQuery();
    }
    function currentLayout(raw) {
        return root.backend.currentLayout(raw);
    }
    function layoutNames(raw) {
        return root.backend.layoutNames(raw);
    }
    // current and count are the layout set before and the number of layouts.
    function setLayout(index, current, count) {
        return root.backend.setLayout(index, current, count);
    }
}
