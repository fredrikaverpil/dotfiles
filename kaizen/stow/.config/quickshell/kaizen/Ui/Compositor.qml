pragma Singleton

import QtQuick
import Quickshell
import "compositors/Niri.js" as Niri

Singleton {
    readonly property string name: Niri.name
    // What differs between compositors; Niri.js says what each means.
    readonly property bool releaseExclusiveFocus: Niri.releaseExclusiveFocus
    readonly property bool replacesDeadLock: Niri.replacesDeadLock
    readonly property bool opensOnFocusedOutput: Niri.opensOnFocusedOutput
    readonly property bool floatsInWorkingArea: Niri.floatsInWorkingArea
    // Components with ids(output), activeId(output) and occupied(idx, output);
    // and with sharing, true while a screencast runs.
    readonly property url workspaceSource: Qt.resolvedUrl("compositors/" + Niri.workspaceComponent)
    readonly property url castSource: Qt.resolvedUrl("compositors/" + Niri.castComponent)

    function dpms(on) {
        return Niri.dpms(on);
    }
    function closeWindow() {
        return Niri.closeWindow();
    }
    function screenshot(mode, path) {
        return Niri.screenshot(mode, path);
    }
    function pickColor() {
        return Niri.pickColor();
    }
    function configFile(home, niriConfig) {
        return Niri.configFile(home, niriConfig);
    }
    function readBinds(file, home, read) {
        return Niri.readBinds(file, home, read);
    }
    function keycaps(chord) {
        return Niri.keycaps(chord);
    }
    function focusWorkspace(id, output) {
        return Niri.focusWorkspace(id, output);
    }
    function focusApp(pattern) {
        return Niri.focusApp(pattern);
    }
    function focusMonitor(output) {
        return Niri.focusMonitor(output);
    }
    function outputs() {
        return Niri.outputs();
    }
    function focusedOutputOn(output) {
        return Niri.focusedOutputOn(output);
    }
    function focusedMonitor(raw) {
        return Niri.focusedMonitor(raw);
    }
    function events() {
        return Niri.events();
    }
    function moveFloatingWindow(id, x, y) {
        return Niri.moveFloatingWindow(id, x, y);
    }
    function pinWindow(raw, appId, state) {
        return Niri.pinWindow(raw, appId, state);
    }
    function layoutQuery() {
        return Niri.layoutQuery();
    }
    function currentLayout(raw) {
        return Niri.currentLayout(raw);
    }
    function layoutNames(raw) {
        return Niri.layoutNames(raw);
    }
    function setLayout(index) {
        return Niri.setLayout(index);
    }
}
