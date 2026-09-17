pragma Singleton

import QtQuick
import Quickshell
import "compositors/Niri.js" as Niri

Singleton {
  readonly property string name: Niri.name

  function dpms(on) { return Niri.dpms(on) }
  function closeWindow() { return Niri.closeWindow() }
  function screenshot(mode) { return Niri.screenshot(mode) }
  function pickColor() { return Niri.pickColor() }
  function focusWorkspace(id, output) { return Niri.focusWorkspace(id, output) }
  function focusMonitor(output) { return Niri.focusMonitor(output) }
  function outputs() { return Niri.outputs() }
  function focusedOutputOn(output) { return Niri.focusedOutputOn(output) }
  function focusedMonitor(raw) { return Niri.focusedMonitor(raw) }
  function events() { return Niri.events() }
  function moveFloatingWindow(id, x, y) { return Niri.moveFloatingWindow(id, x, y) }
  function pinWindow(raw, appId, state) { return Niri.pinWindow(raw, appId, state) }
  function layoutQuery() { return Niri.layoutQuery() }
  function currentLayout(raw) { return Niri.currentLayout(raw) }
  function setLayout(index) { return Niri.setLayout(index) }
}
