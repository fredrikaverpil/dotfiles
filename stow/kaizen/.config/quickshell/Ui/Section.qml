import QtQuick

// A panel section: a heading above its content.
Column {
  id: section

  required property var shell
  required property string title

  width: parent ? parent.width : 0
  spacing: 6

  Text {
    color: section.shell.palette.off
    font.family: Fonts.mono
    font.pixelSize: 11
    font.capitalization: Font.AllUppercase
    font.letterSpacing: 1.5
    text: section.title
  }
}
