pragma Singleton

import QtQuick
import Quickshell
import "compositors/Niri.js" as Niri

Singleton {
  readonly property string name: Niri.name
  readonly property string themeConfig: Quickshell.env("HOME") + Niri.themeConfig

  function dpms(on) { return Niri.dpms(on) }
  function closeWindow() { return Niri.closeWindow() }
  function screenshot(mode) { return Niri.screenshot(mode) }
  function focusWorkspace(id, output) { return Niri.focusWorkspace(id, output) }
  function focusMonitor(output) { return Niri.focusMonitor(output) }
  function outputs() { return Niri.outputs() }
  function focusedMonitor(raw) { return Niri.focusedMonitor(raw) }
  function themeEdits(palette) { return Niri.themeEdits(palette) }
  function layoutQuery() { return Niri.layoutQuery() }
  function currentLayout(raw) { return Niri.currentLayout(raw) }
  function setLayout(index) { return Niri.setLayout(index) }
}
