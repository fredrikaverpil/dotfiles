import QtQuick

// A group inside a group (Wi-Fi's networks by security), indented: a heading row with a chevron, its label, a
// rule and its count, which collapses or expands the rows under it (style.md › Panels).
Column {
    id: subsection

    required property var shell
    property string title: ""
    property string value: ""
    property bool expanded: true

    signal toggled

    default property alias content: body.data

    width: parent ? parent.width : 0
    leftPadding: Space.indent
    spacing: 4

    // The fill reaches 8 past the chevron, as a row's past its mark.
    PanelRow {
        id: heading

        width: subsection.width - subsection.leftPadding
        shell: subsection.shell
        onActivated: subsection.toggled()

        Text {
            id: chevron
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            horizontalAlignment: Text.AlignHCenter
            color: subsection.shell.palette.fg
            font.family: Fonts.mono
            font.pixelSize: 14
            text: subsection.expanded ? "󰅀" : "󰅂"
        }

        Text {
            id: titleText
            anchors.left: chevron.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            color: subsection.shell.palette.fg
            font.family: Fonts.mono
            font.pixelSize: 14
            text: subsection.title
        }

        Rectangle {
            x: titleText.x + titleText.width + 8
            width: (subsection.value !== "" ? valueText.x - 8 : parent.width) - x
            anchors.verticalCenter: parent.verticalCenter
            height: 1
            color: subsection.shell.palette.dim
        }

        Text {
            id: valueText
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            color: subsection.shell.palette.off
            font.family: Fonts.mono
            font.pixelSize: 14
            text: subsection.value
        }
    }

    Column {
        id: body
        visible: subsection.expanded
        width: heading.width
        spacing: 4
    }
}
