pragma Singleton

import QtQuick
import Quickshell

import "CompositorModel.js" as Model

Singleton {
  id: root

  readonly property bool niri: !!Quickshell.env("NIRI_SOCKET")

  function dpms(on) { return Model.dpms(niri, on) }

  function closeWindow() { return Model.closeWindow(niri) }

  function focusWorkspace(id) { return Model.focusWorkspace(niri, id) }

  function outputs() { return Model.outputs(niri) }

  function setScale(name, mode, scale) { return Model.setScale(niri, name, mode, scale) }

  readonly property string scaleConfig: Quickshell.env("HOME") +
    (niri ? "/.config/niri/config.kdl" : "/.config/hypr/monitors.lua")

  function scaleEdits(scale, gdkScale) { return Model.scaleEdits(niri, scale, gdkScale) }

  function layoutQuery() { return Model.layoutQuery(niri) }

  function setLayout(index) { return Model.setLayout(niri, index) }

  readonly property var nightlightBackend: Model.nightlightBackend(niri)
}
