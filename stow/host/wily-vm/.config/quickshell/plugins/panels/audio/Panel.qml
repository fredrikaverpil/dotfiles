import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

import "../../../Ui" as Ui

// Output volume, mute and the default-sink pick, straight off Quickshell's
// PipeWire service -- no wpctl subprocess. Deliberately without Omarchy's
// per-app stream mixer and input section; see wily-vm/CLAUDE.md.
Ui.Panel {
  id: root

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var sinks: Pipewire.nodes
    ? Pipewire.nodes.values.filter(node => node && node.isSink && !node.isStream)
    : []
  readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
  readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
  readonly property string icon: muted || volume <= 0
    ? "󰝟"
    : volume < 0.34 ? "󰕿" : volume < 0.67 ? "󰖀" : "󰕾"

  // One cursor for keyboard and mouse: -1 is the slider row, 0..n-1 the
  // device rows. Hover moves it, the visuals read it, so only ever one
  // highlight is on screen.
  property int cursor: -1

  cardWidth: 480
  cardHeight: 140 + sinks.length * 38

  function label(node) {
    return node ? (node.nickname || node.description || node.name || "Unknown") : ""
  }

  function setVolume(value) {
    if (!sink || !sink.audio) return
    sink.audio.volume = Math.max(0, Math.min(1, value))
  }

  // h/l is a no-op on a device row: moving the output volume from a row that
  // is not the slider surprises people.
  function adjust(delta) { if (cursor < 0) setVolume(volume + delta) }

  function toggleMute() { if (sink && sink.audio) sink.audio.muted = !sink.audio.muted }

  function setDefault(node) { if (node) Pipewire.preferredDefaultAudioSink = node }

  function moveCursor(delta) {
    cursor = Math.max(-1, Math.min(sinks.length - 1, cursor + delta))
  }

  function activate() {
    if (cursor < 0) toggleMute()
    else setDefault(sinks[cursor])
  }

  // Every open starts on the slider rather than wherever the last visit left
  // the cursor.
  onShownChanged: if (shown) {
    cursor = -1
    keys.forceActiveFocus()
  }

  // Without this the node properties never bind: volume reads 0 forever.
  PwObjectTracker { objects: root.sinks }

  // No `show` function: `qs ipc show` is a CLI subcommand and the call never
  // reaches the handler.
  IpcHandler {
    target: "audio"

    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
    function up(): void { root.setVolume(root.volume + 0.05) }
    function down(): void { root.setVolume(root.volume - 0.05) }
    function mute(): void { root.toggleMute() }
    function setVolume(percent: int): void { root.setVolume(percent / 100) }
    function status(): string {
      return JSON.stringify({
        volume: Math.round(root.volume * 100),
        muted: root.muted,
        sink: root.label(root.sink),
      })
    }
  }

  // This panel keeps its own cursor instead of walking Qt's focus chain like
  // the keyNavigation panels, so it takes the keys itself: h/l on the slider
  // row changes a value, which a focus chain cannot express.
  Item {
    id: keys
    width: 0
    height: 0
    focus: true

    Keys.onPressed: function (event) {
      if (event.key === Qt.Key_Escape) root.close()
      else if (event.key === Qt.Key_Down || event.text === "j") root.moveCursor(1)
      else if (event.key === Qt.Key_Up || event.text === "k") root.moveCursor(-1)
      else if (event.key === Qt.Key_Right || event.text === "l") root.adjust(0.05)
      else if (event.key === Qt.Key_Left || event.text === "h") root.adjust(-0.05)
      else if (event.text === "m") root.toggleMute()
      else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
        || event.key === Qt.Key_Space) root.activate()
      else return
      event.accepted = true
    }
  }

  Text {
    width: parent.width
    color: root.shell.palette.fg
    font.family: "JetBrainsMono Nerd Font"
    font.pixelSize: 18
    text: "Audio"
  }

  Text {
    width: parent.width
    elide: Text.ElideRight
    color: root.shell.palette.off
    font.family: "JetBrainsMono Nerd Font"
    font.pixelSize: 13
    text: root.sink
      ? root.label(root.sink) + " · " + Math.round(root.volume * 100) + "%"
      : "No output"
  }

  Rectangle {
    width: parent.width
    height: 1
    color: root.shell.palette.dim
  }

  Rectangle {
    id: slider

    width: parent.width
    height: 38
    radius: 4
    color: "transparent"
    border.color: root.cursor < 0 ? root.shell.palette.fg : root.shell.palette.dim
    border.width: 1

    Text {
      id: sliderIcon
      anchors.left: parent.left
      anchors.leftMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      color: root.shell.palette.fg
      font.family: "JetBrainsMono Nerd Font"
      font.pixelSize: 16
      text: root.icon
    }

    Rectangle {
      id: track
      anchors.left: sliderIcon.right
      anchors.leftMargin: 10
      anchors.right: parent.right
      anchors.rightMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      height: 6
      radius: 3
      color: root.shell.palette.dim

      Rectangle {
        width: parent.width * root.volume
        height: parent.height
        radius: parent.radius
        color: root.muted ? root.shell.palette.off : root.shell.palette.fg
      }

      MouseArea {
        anchors.fill: parent
        anchors.margins: -12
        hoverEnabled: true
        onEntered: root.cursor = -1
        onPositionChanged: function (mouse) { if (pressed) root.setVolume(mouse.x / width) }
        onPressed: function (mouse) { root.setVolume(mouse.x / width) }
      }
    }

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.NoButton
      hoverEnabled: true
      onEntered: root.cursor = -1
    }
  }

  Repeater {
    model: root.sinks

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
        anchors.right: mark.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        elide: Text.ElideRight
        color: root.shell.palette.fg
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13
        text: root.label(modelData)
      }

      Text {
        id: mark
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        color: root.shell.palette.fg
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13
        text: modelData === root.sink ? "󰄬" : ""
      }

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.cursor = index
        onClicked: root.setDefault(modelData)
      }
    }
  }
}
