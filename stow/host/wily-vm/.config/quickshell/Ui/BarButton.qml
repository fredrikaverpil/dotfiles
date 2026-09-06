import QtQuick

Rectangle {
  id: btn

  required property var shell
  property alias label: btnLabel.text
  property alias image: btnImage.source
  property string fontFamily: "JetBrainsMono Nerd Font"
  property real fontSize: 14
  property color foreground: btn.shell.palette.fg

  signal activated
  signal secondary

  implicitWidth: visible ? 28 : 0
  width: implicitWidth
  height: 24
  radius: 4
  color: btnMouse.containsMouse ? btn.shell.palette.sel : "transparent"

  TextMetrics {
    id: btnMetrics
    font.family: btnLabel.font.family
    font.pixelSize: btnLabel.font.pixelSize
    text: btnLabel.text
  }

  Image {
    id: btnImage
    anchors.centerIn: parent
    width: 16
    height: 16
    visible: status === Image.Ready
    fillMode: Image.PreserveAspectFit
    asynchronous: true
    sourceSize.width: width * Screen.devicePixelRatio
    sourceSize.height: height * Screen.devicePixelRatio
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

  MouseArea {
    id: btnMouse
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: function (mouse) {
      if (mouse.button === Qt.RightButton) btn.secondary()
      else btn.activated()
    }
  }
}
