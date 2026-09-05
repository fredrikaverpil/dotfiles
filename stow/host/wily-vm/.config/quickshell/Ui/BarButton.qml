import QtQuick

// Bar chrome, so every button hovers and reads the same. Keep an icon slot
// independent of its glyph: the light and dark symbols have different font
// advances, and a content-sized slot makes its neighbour jump on a toggle.
//
// A button hidden by `visible` gives its slot back, so an indicator that only
// appears while its state is non-default costs nothing while it is off. See
// the bar strategy in wily-vm/CLAUDE.md.
//
// One slot, two sources: an app-supplied image when it loads, the glyph
// otherwise. Tray items are the only user of the image path -- their icon is
// a pixmap the app chose, not something we can express in the Nerd Font.
Rectangle {
  id: btn

  required property var shell
  property alias label: btnLabel.text
  property alias image: btnImage.source
  property string fontFamily: "JetBrainsMono Nerd Font"
  // Overridable so a button can mark itself without taking a second slot;
  // the tray raises it to `sel` for a NeedsAttention item.
  property color foreground: btn.shell.palette.fg

  signal activated
  // Right click. The fixed buttons ignore it; a tray item opens its menu.
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
    // Text centers its advance box, not the pixels it paints. Correct that
    // horizontal difference so differently shaped Nerd Font glyphs share a
    // visual centre in the fixed slot.
    // The glyph's own advance width, not the button's fixed slot: the
    // correction is between where Text puts the advance box and where the ink
    // actually sits inside it.
    anchors.horizontalCenterOffset: btnLabel.implicitWidth / 2
      - (btnMetrics.tightBoundingRect.x + btnMetrics.tightBoundingRect.width / 2)
    color: btn.foreground
    font.family: btn.fontFamily
    font.pixelSize: 14 * btn.shell.textScale
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
