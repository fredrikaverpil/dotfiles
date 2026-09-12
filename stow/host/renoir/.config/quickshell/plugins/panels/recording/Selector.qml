import QtQuick
import Quickshell
import Quickshell.Wayland

import "../../services/recording/RecordingModel.js" as Model
import "../../../Ui" as Ui

// Draws the recording region over every output; the region stays on one.
// While counting down or recording it stays, click-through, to show what is captured.
Scope {
  id: root

  required property var shell
  required property var service

  // Logical, global coordinates.
  property var rect: ({ x: 0, y: 0, width: 0, height: 0 })
  readonly property var shown: service.selecting ? rect : service.shownRegion
  readonly property var screen: shown ? Model.screenAt(service.screens, shown) : null

  function move(dx, dy) {
    rect = Model.clampRegion({ x: rect.x + dx, y: rect.y + dy, width: rect.width, height: rect.height }, screen)
  }

  function resize(dw, dh) {
    rect = Model.clampRegion({ x: rect.x, y: rect.y, width: rect.width + dw, height: rect.height + dh }, screen)
  }

  Connections {
    target: root.service
    function onSelectingChanged() {
      if (root.service.selecting) root.rect = Model.initialRegion(root.service.region, root.service.screens)
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: window

      required property var modelData
      readonly property bool active: root.screen !== null && root.screen.name === modelData.name
      // The region in this window's coordinates.
      readonly property real rx: root.shown ? root.shown.x - modelData.x : 0
      readonly property real ry: root.shown ? root.shown.y - modelData.y : 0
      readonly property real rw: root.shown ? root.shown.width : 0
      readonly property real rh: root.shown ? root.shown.height : 0

      screen: modelData
      visible: root.shown !== null
      anchors { top: true; bottom: true; left: true; right: true }
      exclusionMode: ExclusionMode.Ignore
      color: "transparent"
      WlrLayershell.namespace: "wily-recording-region"
      WlrLayershell.layer: WlrLayer.Overlay
      // Only one surface may hold exclusive focus; the others still take the pointer.
      WlrLayershell.keyboardFocus: root.service.selecting && active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
      mask: root.service.selecting ? null : passThrough

      Region { id: passThrough }

      readonly property color shade: root.shell.dark ? "#991C1917" : "#99F0EDEC"

      Rectangle { x: 0; y: 0; width: parent.width; height: window.active ? Math.max(0, window.ry) : parent.height; color: window.shade }
      Rectangle {
        visible: window.active
        x: 0; y: window.ry + window.rh
        width: parent.width; height: Math.max(0, parent.height - y)
        color: window.shade
      }
      Rectangle {
        visible: window.active
        x: 0; y: window.ry; width: Math.max(0, window.rx); height: window.rh
        color: window.shade
      }
      Rectangle {
        visible: window.active
        x: window.rx + window.rw; y: window.ry
        width: Math.max(0, parent.width - x); height: window.rh
        color: window.shade
      }

      Rectangle {
        visible: window.active
        // The gap keeps gsr's rounding to even pixels from capturing the outline.
        x: window.rx - 4; y: window.ry - 4
        width: window.rw + 8; height: window.rh + 8
        color: "transparent"
        border.color: "#D9534F"
        border.width: 2
      }

      Rectangle {
        visible: window.active && root.service.selecting
        x: Math.min(window.rx, parent.width - width - 8)
        y: window.ry >= height + 8 ? window.ry - height - 6 : window.ry + window.rh + 6
        width: label.implicitWidth + 16
        height: label.implicitHeight + 8
        radius: 4
        color: root.shell.palette.bg
        border.color: root.shell.palette.dim

        Text {
          id: label
          anchors.centerIn: parent
          color: root.shell.palette.fg
          font.family: Ui.Fonts.mono
          font.pixelSize: 13
          text: Math.round(window.rw) + "×" + Math.round(window.rh)
            + "  hjkl move · HJKL size · Ctrl fine · Tab monitor · Enter record · Esc cancel"
        }
      }

      MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.service.selecting
        property real startX: 0
        property real startY: 0
        property var startRect: null
        property bool moving: false

        onPressed: function (event) {
          const gx = event.x + window.modelData.x
          const gy = event.y + window.modelData.y
          const r = root.rect
          moving = window.active && gx >= r.x && gx < r.x + r.width && gy >= r.y && gy < r.y + r.height
          startX = gx
          startY = gy
          startRect = r
        }
        onPositionChanged: function (event) {
          const gx = event.x + window.modelData.x
          const gy = event.y + window.modelData.y
          const s = window.modelData
          const bounds = { x: s.x, y: s.y, width: s.width, height: s.height }
          root.rect = moving
            ? Model.clampRegion({ x: startRect.x + gx - startX, y: startRect.y + gy - startY,
              width: startRect.width, height: startRect.height }, bounds)
            : Model.clampRegion(Model.spanRegion(startX, startY, gx, gy), bounds)
        }
      }

      Item {
        focus: true
        Keys.onPressed: function (event) {
          const step = event.modifiers & Qt.ControlModifier ? 1 : 20
          if (event.key === Qt.Key_Escape) root.service.cancel()
          else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.service.confirmRegion(root.rect)
          else if (event.key === Qt.Key_Tab) root.rect = Model.nextScreenRegion(root.rect, root.service.screens)
          else if (event.text === "h" || event.key === Qt.Key_Left) root.move(-step, 0)
          else if (event.text === "l" || event.key === Qt.Key_Right) root.move(step, 0)
          else if (event.text === "k" || event.key === Qt.Key_Up) root.move(0, -step)
          else if (event.text === "j" || event.key === Qt.Key_Down) root.move(0, step)
          else if (event.text === "H") root.resize(-step, 0)
          else if (event.text === "L") root.resize(step, 0)
          else if (event.text === "K") root.resize(0, -step)
          else if (event.text === "J") root.resize(0, step)
          else return
          event.accepted = true
        }
      }
    }
  }
}
