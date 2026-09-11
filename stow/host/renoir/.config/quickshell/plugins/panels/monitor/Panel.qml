import QtQuick
import Quickshell
import Quickshell.Io

import "../../../Ui" as Ui

Ui.Panel {
  id: root

  property var focusedMonitor: null

  readonly property var textScales: [0.8, 0.9, 1, 1.1, 1.25, 1.5]

  cardHeight: 410
  keyNavigation: true

  function refresh() {
    if (!monitorState.running) monitorState.running = true
  }

  function setMonitorState(raw) {
    focusedMonitor = Ui.Compositor.focusedMonitor(raw)
  }

  onShownChanged: if (shown) refresh()

  IpcHandler {
    target: "display"

    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
    function status(): string {
      return JSON.stringify({
        monitor: root.focusedMonitor ? root.focusedMonitor.name : "",
        textScale: root.shell.textScale,
      })
    }
  }

  Process {
    id: monitorState
    command: Ui.Compositor.outputs()
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.setMonitorState(text)
    }
  }

  Text {
    width: parent.width
    color: root.shell.palette.fg
    font.family: Ui.Fonts.mono
    font.pixelSize: 18
    text: "Display"
  }

  Text {
    width: parent.width
    color: root.shell.palette.off
    font.family: Ui.Fonts.mono
    font.pixelSize: 13
    text: root.focusedMonitor
      ? root.focusedMonitor.name + " · " + root.focusedMonitor.width + "×" + root.focusedMonitor.height
      : "No active display"
  }

  Rectangle {
    width: parent.width
    height: 1
    color: root.shell.palette.dim
  }

  Section {
    title: "Theme"

    ChoiceRow {
      options: [
        { label: "Light", value: false },
        { label: "Dark", value: true },
      ]
      selected: root.shell.dark
      onChosen: value => root.shell.setDark(value)
    }
  }

  Section {
    title: root.shell.nightlight.temperature === null
      ? "Nightlight"
      : "Nightlight · " + root.shell.nightlight.temperature + "K"

    ChoiceRow {
      options: [
        { label: "Off", value: "off" },
        { label: "Auto", value: "auto" },
        { label: "On", value: "on" },
      ]
      selected: root.shell.nightlight.mode
      onChosen: value => root.shell.nightlight.setMode(value)
    }
  }

  Section {
    title: "Text size · " + Math.round(root.shell.textScale * 100) + "%"

    ChoiceRow {
      options: root.textScales.map(value => ({ label: Math.round(value * 100) + "%", value: value }))
      selected: root.shell.textScale
      matches: (value, selected) => Math.abs(Number(value) - Number(selected)) < 0.01
      onChosen: value => root.shell.setTextScale(value)
    }
  }

  DimRow {
    label: "Brightness"
    detail: "Unavailable in this VM"
  }

  // Layout, mode and scale are saved by nwg-displays to niri/monitor.kdl.
  ChoiceButton {
    width: parent.width
    label: "Arrange displays…"
    onActivated: {
      Quickshell.execDetached(["uwsm-app", "--", "nwg-displays.desktop"])
      root.close()
    }
  }

  component Section: Column {
    required property string title

    width: parent.width
    spacing: 5

    Text {
      color: root.shell.palette.off
      font.family: Ui.Fonts.mono
      font.pixelSize: 13
      text: parent.title
    }
  }

  component ChoiceRow: Row {
    id: choices

    property var options: []
    property var selected
    property bool available: true
    property var matches: (value, selected) => value === selected
    signal chosen(var value)

    width: parent.width
    spacing: 6

    Repeater {
      id: optionRepeater
      model: choices.options

      delegate: ChoiceButton {
        required property var modelData
        required property int index

        width: (choices.width - choices.spacing * (optionRepeater.count - 1)) / optionRepeater.count
        label: modelData.label
        active: choices.matches(modelData.value, choices.selected)
        available: choices.available
        onActivated: choices.chosen(modelData.value)
      }
    }
  }

  component ChoiceButton: Rectangle {
    id: button

    property string label: ""
    property bool active: false
    property bool available: true
    signal activated

    height: 30
    radius: 4
    color: active ? root.shell.palette.sel : "transparent"
    border.color: button.activeFocus ? root.shell.palette.fg : root.shell.palette.dim
    border.width: 1
    opacity: available ? 1 : 0.45

    // Keep an unavailable visible button in the chain; removing focused controls strands focus.
    activeFocusOnTab: true
    Keys.onReturnPressed: if (button.available) button.activated()
    Keys.onEnterPressed: if (button.available) button.activated()
    Keys.onSpacePressed: if (button.available) button.activated()

    Text {
      anchors.centerIn: parent
      color: root.shell.palette.fg
      font.family: Ui.Fonts.mono
      font.pixelSize: 14
      text: button.label
    }

    MouseArea {
      anchors.fill: parent
      enabled: button.available
      hoverEnabled: true
      onClicked: button.activated()
    }
  }

  component DimRow: Rectangle {
    required property string label
    required property string detail

    width: parent.width
    height: 28
    radius: 4
    color: "transparent"
    border.color: root.shell.palette.dim
    border.width: 1

    Text {
      anchors.left: parent.left
      anchors.leftMargin: 8
      anchors.verticalCenter: parent.verticalCenter
      color: root.shell.palette.off
      font.family: Ui.Fonts.mono
      font.pixelSize: 13
      text: parent.label
    }

    Text {
      anchors.right: parent.right
      anchors.rightMargin: 8
      anchors.verticalCenter: parent.verticalCenter
      color: root.shell.palette.off
      font.family: Ui.Fonts.mono
      font.pixelSize: 13
      text: parent.detail
    }
  }
}
