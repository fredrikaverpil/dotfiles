// Notification card shared by the live toast stack and recent-history panel.
// Its path mirrors Omarchy's component so upstream visual and behavior changes
// remain easy to compare without bringing in Omarchy's shared QML framework.

import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
  id: root

  property var palette: ({ bg: "#1C1917", fg: "#B4BDC3", sel: "#3D4042", dim: "#403833", off: "#6E6864" })
  property var row: ({})
  property var notification: null
  property bool toast: false
  property int duration: 0
  property bool hovered: hoverHandler.hovered
  property real remaining: 1.0

  signal closeRequested()
  signal invokeRequested()
  signal actionRequested(var action)
  signal expired()

  readonly property string app: String(row.app || "")
  readonly property string appIcon: String(row.appIcon || "")
  readonly property string summary: String(row.summary || "")
  readonly property string body: String(row.body || "")
  readonly property string image: String(row.image || "")
  readonly property int urgency: Number(row.urgency)
  readonly property var actions: notification ? notification.actions : []
  readonly property color accent: urgency === 2 ? "#C94F46" : (urgency === 0 ? palette.off : palette.fg)
  readonly property string icon: {
    if (image) return image
    if (!appIcon) return ""
    if (appIcon.indexOf("file://") === 0 || appIcon.indexOf("image://") === 0) return appIcon
    if (appIcon.charAt(0) === "/") return "file://" + appIcon
    return Quickshell.iconPath(appIcon, true)
  }

  width: 400
  implicitHeight: content.implicitHeight + 24
  radius: 8
  color: palette.bg
  border.color: accent
  border.width: 1
  clip: true

  HoverHandler { id: hoverHandler }

  // This is behind the content so an explicit action or close button wins.
  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onClicked: function(mouse) {
      if (mouse.button === Qt.RightButton) root.closeRequested()
      else root.invokeRequested()
    }
  }

  ColumnLayout {
    id: content
    anchors.fill: parent
    anchors.margins: 12
    spacing: 8

    RowLayout {
      Layout.fillWidth: true
      spacing: 10

      Image {
        Layout.preferredWidth: visible ? 40 : 0
        Layout.preferredHeight: visible ? 40 : 0
        visible: root.icon.length > 0 && status !== Image.Error
        source: root.icon
        sourceSize.width: 80
        sourceSize.height: 80
        fillMode: Image.PreserveAspectFit
        asynchronous: true
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 3

        Text {
          Layout.fillWidth: true
          text: root.summary || root.app
          textFormat: Text.PlainText
          color: root.palette.fg
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 14
          font.bold: true
          wrapMode: Text.WordWrap
          maximumLineCount: 2
          elide: Text.ElideRight
        }

        Text {
          Layout.fillWidth: true
          visible: root.body.length > 0
          text: root.body
          textFormat: Text.PlainText
          color: root.palette.off
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 13
          wrapMode: Text.WordWrap
          maximumLineCount: root.toast ? 3 : 8
          elide: Text.ElideRight
        }

        Text {
          Layout.fillWidth: true
          visible: !root.toast && Number(root.row.timestamp) > 0
          text: Qt.formatDateTime(new Date(Number(root.row.timestamp)), "ddd HH:mm")
          color: root.palette.off
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 11
        }
      }

      Rectangle {
        Layout.alignment: Qt.AlignTop
        width: 20
        height: 20
        radius: 4
        color: closeArea.containsMouse ? root.palette.sel : "transparent"

        Text {
          anchors.centerIn: parent
          text: "×"
          color: root.palette.off
          font.pixelSize: 18
        }

        MouseArea {
          id: closeArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.closeRequested()
        }
      }
    }

    RowLayout {
      Layout.fillWidth: true
      visible: root.actions.length > 0
      spacing: 6

      Repeater {
        model: root.actions

        delegate: Rectangle {
          required property var modelData

          visible: modelData.identifier !== "default"
          implicitWidth: actionLabel.implicitWidth + 16
          implicitHeight: 26
          radius: 4
          color: actionArea.containsMouse ? root.palette.sel : "transparent"
          border.color: root.palette.dim
          border.width: 1

          Text {
            id: actionLabel
            anchors.centerIn: parent
            text: modelData.text
            textFormat: Text.PlainText
            color: root.palette.fg
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
          }

          MouseArea {
            id: actionArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.actionRequested(modelData)
          }
        }
      }
    }
  }

  Rectangle {
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    width: parent.width * root.remaining
    height: root.toast && root.duration > 0 ? 2 : 0
    color: root.accent
  }

  Timer {
    interval: 50
    repeat: true
    running: root.toast && root.duration > 0 && !root.hovered
    onTriggered: {
      root.remaining -= interval / root.duration
      if (root.remaining <= 0) {
        root.remaining = 0
        root.expired()
      }
    }
  }
}
