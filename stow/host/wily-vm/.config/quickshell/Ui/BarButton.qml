import QtQuick

// Fixed-width icon slot: glyphs differ in font advance, so a content-sized
// slot would make neighbours jump on a toggle. A button hidden by `visible`
// gives its slot back.
//
// Two sources for the slot: an app-supplied image when it loads, the glyph
// otherwise. Only tray items use the image path.
Rectangle {
  id: btn

  required property var shell
  property alias label: btnLabel.text
  property alias image: btnImage.source
  property string fontFamily: "JetBrainsMono Nerd Font"
  property real fontSize: 14
  // Overridable so a button can mark itself without taking a second slot; the
  // tray raises it to `sel` for a NeedsAttention item.
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
    // Decode at physical pixels; a logical-size decode leaves PNG icons
    // upscaled and blurry.
    sourceSize.width: width * Screen.devicePixelRatio
    sourceSize.height: height * Screen.devicePixelRatio
  }

  Text {
    id: btnLabel
    anchors.centerIn: parent
    visible: !btnImage.visible
    // Text centers its advance box, not the ink. Correct the difference
    // between the two so differently shaped glyphs share a visual centre.
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
