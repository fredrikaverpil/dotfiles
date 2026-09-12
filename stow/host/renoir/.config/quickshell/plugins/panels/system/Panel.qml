import QtQuick
import Quickshell
import Quickshell.Io

import "../../../Ui" as Ui
import "../../services/system/SystemModel.js" as Model

Ui.Panel {
  id: root

  required property var service

  cardWidth: 600
  cardHeight: 460
  keyNavigation: true

  IpcHandler {
    target: "system"

    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
    function status(): string { return root.service.status() }
  }

  Row {
    width: parent.width
    spacing: 8

    Text {
      width: parent.width - btopButton.width - parent.spacing
      color: root.shell.palette.fg
      font.family: Ui.Fonts.mono
      font.pixelSize: 18
      text: "System"
    }

    ActionButton {
      id: btopButton
      width: 110
      label: "Open btop"
      onActivated: {
        root.close()
        Quickshell.execDetached(["ghostty", "-e", "btop"])
      }
    }
  }

  Divider {}

  Metric {
    label: "CPU"
    value: Math.round(root.service.cpu) + "% · "
      + (isFinite(root.service.temperature) ? Math.round(root.service.temperature) + " °C" : "--")
      + " · load " + root.service.load
  }

  Sparkline {
    values: root.service.cpuHistory
  }

  Row {
    id: coreRow
    width: parent.width
    height: 24
    spacing: 3

    Repeater {
      model: root.service.cores

      delegate: Rectangle {
        id: core
        required property real modelData
        width: (coreRow.width - coreRow.spacing * (root.service.cores.length - 1)) / root.service.cores.length
        height: coreRow.height
        radius: 2
        color: root.shell.palette.dim

        Rectangle {
          anchors.bottom: parent.bottom
          width: parent.width
          height: parent.height * core.modelData / 100
          radius: parent.radius
          color: root.shell.palette.fg
        }
      }
    }
  }

  Metric {
    label: "Memory"
    value: Model.formatUsage(root.service.memory.total - root.service.memory.available, root.service.memory.total)
      + " · swap " + Model.formatUsage(root.service.memory.swapTotal - root.service.memory.swapFree,
        root.service.memory.swapTotal)
  }

  Sparkline {
    values: root.service.memoryHistory
  }

  Metric {
    label: "Network" + (root.service.networkInterface !== "" ? " · " + root.service.networkInterface : "")
    value: "↓ " + Model.formatRate(root.service.rxRate) + "  ↑ " + Model.formatRate(root.service.txRate)
  }

  Row {
    id: networkRow
    width: parent.width
    spacing: 8

    Sparkline {
      width: (networkRow.width - networkRow.spacing) / 2
      values: root.service.rxHistory
      maximum: Math.max.apply(null, [1000].concat(root.service.rxHistory))
    }

    Sparkline {
      width: (networkRow.width - networkRow.spacing) / 2
      values: root.service.txHistory
      maximum: Math.max.apply(null, [1000].concat(root.service.txHistory))
    }
  }

  Divider {}

  Column {
    width: parent.width
    spacing: 2

    ProcessRow {
      name: "Process"
      cpu: "CPU"
      memory: "MEM"
      foreground: root.shell.palette.off
    }

    Repeater {
      model: root.service.processes

      delegate: ProcessRow {
        required property var modelData
        name: modelData.name
        cpu: modelData.cpu.toFixed(1) + "%"
        memory: modelData.memory.toFixed(1) + "%"
      }
    }
  }

  component Divider: Rectangle {
    width: parent.width
    height: 1
    color: root.shell.palette.dim
  }

  component Metric: Item {
    id: metric

    property string label: ""
    property string value: ""

    width: parent.width
    height: 18

    Text {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      color: root.shell.palette.off
      font.family: Ui.Fonts.mono
      font.pixelSize: 13
      text: metric.label
    }

    Text {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      color: root.shell.palette.fg
      font.family: Ui.Fonts.mono
      font.pixelSize: 13
      text: metric.value
    }
  }

  // History fills in from the right, one sample per point.
  component Sparkline: Rectangle {
    id: sparkline

    property var values: []
    property real maximum: 100

    width: parent.width
    height: 40
    radius: 4
    color: "transparent"
    border.color: root.shell.palette.dim
    border.width: 1

    onValuesChanged: canvas.requestPaint()
    onMaximumChanged: canvas.requestPaint()

    Canvas {
      id: canvas

      property color stroke: root.shell.palette.fg
      property color fill: root.shell.palette.sel

      anchors.fill: parent
      anchors.margins: 2

      onStrokeChanged: requestPaint()
      onFillChanged: requestPaint()

      onPaint: {
        const context = getContext("2d")
        context.reset()
        const values = sparkline.values
        if (values.length < 2) return
        const step = canvas.width / (Model.historyLength - 1)
        const offset = Model.historyLength - values.length
        const points = values.map((value, index) => ({
          x: (offset + index) * step,
          y: canvas.height - Math.max(0, Math.min(1, value / sparkline.maximum)) * canvas.height
        }))

        context.beginPath()
        context.moveTo(points[0].x, canvas.height)
        points.forEach(point => context.lineTo(point.x, point.y))
        context.lineTo(points[points.length - 1].x, canvas.height)
        context.closePath()
        context.fillStyle = canvas.fill
        context.fill()

        context.beginPath()
        points.forEach((point, index) => {
          if (index === 0) context.moveTo(point.x, point.y)
          else context.lineTo(point.x, point.y)
        })
        context.strokeStyle = canvas.stroke
        context.lineWidth = 1.5
        context.stroke()
      }
    }
  }

  component ProcessRow: Item {
    id: processRow

    property string name: ""
    property string cpu: ""
    property string memory: ""
    property color foreground: root.shell.palette.fg

    width: parent.width
    height: 18

    Text {
      anchors.left: parent.left
      anchors.right: cpuLabel.left
      anchors.rightMargin: 8
      anchors.verticalCenter: parent.verticalCenter
      elide: Text.ElideRight
      color: processRow.foreground
      font.family: Ui.Fonts.mono
      font.pixelSize: 12
      text: processRow.name
    }

    Text {
      id: cpuLabel
      anchors.right: memoryLabel.left
      anchors.verticalCenter: parent.verticalCenter
      width: 70
      horizontalAlignment: Text.AlignRight
      color: processRow.foreground
      font.family: Ui.Fonts.mono
      font.pixelSize: 12
      text: processRow.cpu
    }

    Text {
      id: memoryLabel
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      width: 70
      horizontalAlignment: Text.AlignRight
      color: processRow.foreground
      font.family: Ui.Fonts.mono
      font.pixelSize: 12
      text: processRow.memory
    }
  }

  component ActionButton: Rectangle {
    id: button

    property string label: ""
    property bool active: false
    signal activated

    height: 28
    radius: 4
    color: active ? root.shell.palette.sel : "transparent"
    border.color: button.activeFocus ? root.shell.palette.fg : root.shell.palette.dim
    border.width: 1

    activeFocusOnTab: button.visible
    Keys.onReturnPressed: button.activated()
    Keys.onEnterPressed: button.activated()
    Keys.onSpacePressed: button.activated()

    Text {
      anchors.centerIn: parent
      color: root.shell.palette.fg
      font.family: Ui.Fonts.mono
      font.pixelSize: 12
      text: button.label
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      onClicked: button.activated()
    }
  }
}
