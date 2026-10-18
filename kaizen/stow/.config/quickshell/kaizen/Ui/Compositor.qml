pragma Singleton

import QtQuick
import Quickshell
import "compositors/Niri.js" as Niri
import "compositors/Umbriel.js" as Umbriel
import "compositors/Unset.js" as Unset

Singleton {
    id: root

    // The session's compositor, read once from KAIZEN_COMPOSITOR, which
    // `kaizen run` exports; Unset when it names none.
    readonly property var backends: ({
            niri: Niri,
            umbriel: Umbriel
        })
    readonly property string configured: Quickshell.env("KAIZEN_COMPOSITOR") || ""
    readonly property var backend: backends.hasOwnProperty(configured) ? backends[configured] : Unset

    readonly property string name: backend.name
    // What differs between compositors; each backend says what each means.
    readonly property bool releaseExclusiveFocus: backend.releaseExclusiveFocus
    readonly property bool replacesDeadLock: backend.replacesDeadLock
    readonly property bool opensOnFocusedOutput: backend.opensOnFocusedOutput
    readonly property bool floatsInWorkingArea: backend.floatsInWorkingArea
    // Components with ids(output), activeId(output) and occupied(idx, output);
    // and with sharing, true while a screencast runs.
    // Empty when the backend has none.
    readonly property url workspaceSource: backend.workspaceComponent ? Qt.resolvedUrl("compositors/" + backend.workspaceComponent) : ""
    readonly property url castSource: backend.castComponent ? Qt.resolvedUrl("compositors/" + backend.castComponent) : ""
    // The file borderColors(palette) fills, under the shell's state dir.
    readonly property string borderFile: backend.borderFile
    // The action closeWindow() runs, as a bind names it.
    readonly property string closeWindowAction: backend.closeWindowAction

    Component.onCompleted: {
        if (backend === Unset)
            console.error("KAIZEN_COMPOSITOR names no compositor:", configured || "it is unset");
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
    function screenshot(mode, path) {
        return root.backend.screenshot(mode, path);
    }
    function pickColor() {
        return root.backend.pickColor();
    }
    function configFile(home, niriConfig) {
        return root.backend.configFile(home, niriConfig);
    }
    function readBinds(file, home, read) {
        return root.backend.readBinds(file, home, read);
    }
    // umbriel chords share niri's syntax.
    function keycaps(chord) {
        return Niri.keycaps(chord);
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
    function events() {
        return root.backend.events();
    }
    function moveFloatingWindow(id, x, y) {
        return root.backend.moveFloatingWindow(id, x, y);
    }
    function pinWindow(raw, appId, state) {
        return root.backend.pinWindow(raw, appId, state);
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
