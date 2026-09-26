import QtQuick
import QtQuick.Effects

Rectangle {
  id: btn

  required property var shell
  property alias label: btnLabel.text
  property alias image: btnImage.source
  property string fontFamily: Fonts.mono
  property real fontSize: 14
  property color foreground: btn.shell.palette.fg

  signal activated
  signal secondary
  signal middle

  implicitWidth: visible ? Math.max(28 * btn.shell.textScale, btnLabel.implicitWidth + 12 * btn.shell.textScale) : 0
  width: implicitWidth
  height: Math.round(24 * btn.shell.textScale)
  radius: 4
  color: btnHover.hovered ?btn.shell.palette.sel : "transparent"

  TextMetrics {
    id: btnMetrics
    font.family: btnLabel.font.family
    font.pixelSize: btnLabel.font.pixelSize
    text: btnLabel.text
  }

  Image {
    id: btnImage
    anchors.centerIn: parent
    width: 16 * btn.shell.textScale
    height: 16 * btn.shell.textScale
    visible: status === Image.Ready
    fillMode: Image.PreserveAspectFit
    asynchronous: true
    sourceSize.width: width * Screen.devicePixelRatio
    sourceSize.height: height * Screen.devicePixelRatio
    layer.enabled: true
    layer.effect: MultiEffect { saturation: -1 }
  }

  Text {
    id: btnLabel
    anchors.centerIn: parent
    visible: !btnImage.visible
    anchors.horizontalCenterOffset: btnLabel.implicitWidth / 2
      - (btnMetrics.tightBoundingRect.x + btnMetrics.tightBoundingRect.width / 2)
    color: btn.foreground
    font.family: btn.fontFamily
    font.pixelSize: btn.fontSize * btn.shell.textScale
  }

  HoverHandler {
    id: btnHover
  }

  // Not a MouseArea: a press that moves compositor focus off a focused surface on
  // another output deactivates the app, which cancels exclusive grabs. A tap's
  // passive grab survives, so the release still clicks.
  TapHandler {
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    onTapped: function (eventPoint, button) {
      if (button === Qt.RightButton) btn.secondary()
      else if (button === Qt.MiddleButton) btn.middle()
      else btn.activated()
    }
  }
}
