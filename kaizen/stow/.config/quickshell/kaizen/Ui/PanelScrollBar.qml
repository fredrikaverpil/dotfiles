import QtQuick
import QtQuick.Controls

// A scrolling panel's bar: 4 px, `dim`, in the card's right padding, shown while the content
// overflows (style.md › Panels). Pass it to the Flickable's `ScrollBar.vertical`.
ScrollBar {
    id: bar

    required property var shell

    width: 4
    padding: 0
    policy: size < 1 ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff

    contentItem: Rectangle {
        radius: 2
        color: bar.shell.palette.dim
    }

    background: Item {}
}
