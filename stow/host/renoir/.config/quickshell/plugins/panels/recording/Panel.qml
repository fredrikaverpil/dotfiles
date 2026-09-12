import QtQuick
import Quickshell.Io

import "../../services/recording/RecordingModel.js" as Model
import "../../../Ui" as Ui

Ui.Panel {
  id: root

  required property var service

  // Options are hidden while busy, so the cursor spans the rows and then the actions.
  readonly property var rows: service.busy ? [] : [
    {
      label: "Source",
      values: service.monitors,
      labels: service.monitors,
      value: service.activeMonitor,
      set: value => root.service.monitor = value,
    },
    {
      label: "Camera",
      values: [""].concat(service.cameras.map(entry => entry.path)),
      labels: ["Off"].concat(service.cameras.map(entry => entry.name)),
      value: service.activeCamera,
      set: value => root.service.camera = value,
    },
    {
      label: "Microphone",
      values: ["", "default_input"].concat(service.mics.map(node => node.name)),
      labels: ["Off", "Default input"].concat(service.mics.map(node => node.description || node.nickname || node.name)),
      value: service.activeMic,
      set: value => root.service.mic = value,
    },
    {
      label: "Desktop audio",
      values: [true, false],
      labels: ["On", "Off"],
      value: service.desktop,
      set: value => root.service.desktop = value,
    },
  ]
  readonly property var actions: service.busy
    ? [
      { label: service.paused ? "Resume" : "Pause", run: () => root.service.togglePause() },
      { label: "Stop", run: () => root.service.stop() },
    ]
    : [{ label: "Record", run: () => root.record() }]
  readonly property int count: rows.length + actions.length

  property int cursor: 0

  cardWidth: 480
  cardHeight: 90 + count * 38

  function record() {
    close()
    service.start()
  }

  function adjust(delta) {
    const row = rows[cursor]
    if (row) row.set(Model.step(row.values, row.value, delta))
  }

  function activate() {
    if (cursor < rows.length) adjust(1)
    else actions[cursor - rows.length].run()
  }

  function moveCursor(delta) { cursor = Math.max(0, Math.min(count - 1, cursor + delta)) }

  // Record is preselected, so Enter starts with the saved choices.
  onShownChanged: if (shown) {
    service.refreshCameras()
    cursor = rows.length
    keys.forceActiveFocus()
  }

  onCountChanged: cursor = Math.min(cursor, count - 1)

  IpcHandler {
    target: "recording"

    function open(): void { root.open() }
    function close(): void { root.close() }
    // Stops or cancels while busy, so one key both opens the panel and ends the recording.
    function toggle(): void { root.service.busy ? root.service.stop() : root.toggle() }
    function start(): void { root.service.start() }
    function stop(): void { root.service.stop() }
    function pause(): void { root.service.togglePause() }
    function status(): string {
      return JSON.stringify({
        recording: root.service.recording,
        paused: root.service.paused,
        countdown: root.service.countdown,
        seconds: root.service.seconds,
        file: root.service.file,
        monitor: root.service.activeMonitor,
        camera: root.service.activeCamera,
        mic: root.service.activeMic,
        desktop: root.service.desktop,
        monitors: root.service.monitors,
        cameras: root.service.cameras,
      })
    }
  }

  Item {
    id: keys
    width: 0
    height: 0
    focus: true

    Keys.onPressed: function (event) {
      if (event.key === Qt.Key_Escape) root.close()
      else if (event.key === Qt.Key_Down || event.text === "j") root.moveCursor(1)
      else if (event.key === Qt.Key_Up || event.text === "k") root.moveCursor(-1)
      else if (event.key === Qt.Key_Right || event.text === "l") root.adjust(1)
      else if (event.key === Qt.Key_Left || event.text === "h") root.adjust(-1)
      else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
        || event.key === Qt.Key_Space) root.activate()
      else return
      event.accepted = true
    }
  }

  Text {
    width: parent.width
    color: root.shell.palette.fg
    font.family: Ui.Fonts.mono
    font.pixelSize: 18
    text: "Record"
  }

  Text {
    width: parent.width
    elide: Text.ElideRight
    color: root.shell.palette.off
    font.family: Ui.Fonts.mono
    font.pixelSize: 13
    text: root.service.busy
      ? (root.service.paused ? "Paused · " : "Recording · ") + Model.elapsed(root.service.seconds)
      : "Saved to ~/Videos"
  }

  Rectangle {
    width: parent.width
    height: 1
    color: root.shell.palette.dim
  }

  Repeater {
    model: root.rows

    delegate: Rectangle {
      required property var modelData
      required property int index

      width: parent.width
      height: 30
      radius: 4
      color: root.cursor === index ? root.shell.palette.sel : "transparent"
      border.color: root.cursor === index ? root.shell.palette.fg : root.shell.palette.dim
      border.width: 1

      Text {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        color: root.shell.palette.fg
        font.family: Ui.Fonts.mono
        font.pixelSize: 13
        text: modelData.label
      }

      Text {
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * 0.6
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideLeft
        color: root.shell.palette.fg
        font.family: Ui.Fonts.mono
        font.pixelSize: 13
        text: "‹ " + (modelData.labels[modelData.values.indexOf(modelData.value)] || "—") + " ›"
      }

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onEntered: root.cursor = index
        onClicked: function (mouse) { root.adjust(mouse.button === Qt.RightButton ? -1 : 1) }
      }
    }
  }

  Repeater {
    model: root.actions

    delegate: Rectangle {
      required property var modelData
      required property int index
      readonly property int position: root.rows.length + index

      width: parent.width
      height: 30
      radius: 4
      color: root.cursor === position ? root.shell.palette.sel : "transparent"
      border.color: root.cursor === position ? root.shell.palette.fg : root.shell.palette.dim
      border.width: 1

      Text {
        anchors.centerIn: parent
        color: root.shell.palette.fg
        font.family: Ui.Fonts.mono
        font.pixelSize: 13
        text: modelData.label
      }

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.cursor = parent.position
        onClicked: parent.modelData.run()
      }
    }
  }
}
