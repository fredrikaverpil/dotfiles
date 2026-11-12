import QtQuick
import QtQuick.Layouts
import QtQuick.Window

import "../../Ui" as Ui
import "components"

Column {
    id: root

    required property var shell
    // The notification service, or the gallery's stand-in.
    required property var service
    // Whether the panel shows: the cards animate only then.
    property bool shown: true

    readonly property int cardWidth: 620
    readonly property int cardHeight: 560
    readonly property bool keyNavigation: true

    signal actionRequested(var row, var action)

    readonly property var focusedItem: historyList.Window.activeFocusItem
    // Map to content coordinates: Flickable coordinates are relative to its viewport.
    onFocusedItemChanged: {
        const item = focusedItem;
        if (!item || !shown || item.parent !== historyContent)
            return;
        const top = item.mapToItem(historyContent, 0, 0).y;
        if (!isFinite(top))
            return;
        if (top < historyList.contentY)
            historyList.contentY = Math.max(0, top);
        else if (top + item.height > historyList.contentY + historyList.height)
            historyList.contentY = top + item.height - historyList.height;
    }

    // Removing rebuilds every delegate, so the focus has to be placed again by
    // position: the card that took the removed one's place, or the header.
    function drop(index) {
        root.service.removeHistory(index);
        Qt.callLater(function () {
            if (historyCards.count === 0) {
                clearButton.forceActiveFocus(Qt.TabFocusReason);
                return;
            }
            const card = historyCards.itemAt(Math.min(index, historyCards.count - 1));
            if (card)
                card.forceActiveFocus(Qt.TabFocusReason);
        });
    }

    width: parent ? parent.width : 0
    height: parent ? parent.height : 0
    spacing: 8

    RowLayout {
        id: historyHeader
        width: parent.width
        spacing: 8

        Text {
            Layout.fillWidth: true
            text: "Notifications"
            color: root.shell.palette.fg
            font.family: Ui.Fonts.mono
            font.pixelSize: 18
        }

        HeaderButton {
            id: clearButton
            label: "Clear"
            onActivated: root.service.clearHistory()
        }

        HeaderButton {
            label: "Enabled"
            active: !root.service.doNotDisturb
            onActivated: root.service.setDoNotDisturb(!root.service.doNotDisturb)
        }
    }

    Rectangle {
        id: historySeparator
        width: parent.width
        height: 1
        color: root.shell.palette.dim
    }

    Item {
        id: historyArea
        width: parent.width
        height: parent.height - historyHeader.height - historySeparator.height - 2 * root.spacing

        // Clips scrolled-out cards but not a glowing card's halo: the clip
        // reaches past the sides, and past an end with nothing scrolled beyond it.
        Item {
            id: historyClip
            readonly property int reach: 64
            readonly property real above: historyList.atYBeginning ? reach : 0
            x: -reach
            y: -above
            width: historyArea.width + 2 * reach
            height: historyArea.height + above + (historyList.atYEnd ? reach : 0)
            clip: true

            // A Flickable over a Column, not a ListView: every card must exist for the
            // panel's focus chain to reach it, and a virtualized delegate does not.
            Flickable {
                id: historyList
                x: historyClip.reach
                y: historyClip.above
                width: historyArea.width
                height: historyArea.height
                contentWidth: width
                contentHeight: historyContent.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: historyContent
                    width: historyList.width
                    spacing: 8

                    Repeater {
                        id: historyCards
                        model: root.service.historyRows

                        delegate: NotificationCard {
                            required property var modelData
                            required property int index

                            width: historyContent.width
                            palette: root.shell.palette
                            row: modelData
                            toast: false
                            animated: root.shown
                            selectable: true
                            onCloseRequested: root.drop(index)
                            onInvokeRequested: {}
                            onActionRequested: action => root.actionRequested(modelData, action)
                        }
                    }

                    Text {
                        visible: historyCards.count === 0
                        text: "No notifcations here yet"
                        color: root.shell.palette.off
                        font.family: Ui.Fonts.mono
                        font.pixelSize: 14
                    }
                }
            }
        }
    }

    component HeaderButton: Rectangle {
        id: button

        property string label: ""
        property bool active: false
        signal activated

        implicitWidth: buttonLabel.implicitWidth + 14
        implicitHeight: 26
        radius: 4
        color: active || buttonMouse.containsMouse ? root.shell.palette.sel : "transparent"
        border.color: button.activeFocus ? root.shell.palette.fg : root.shell.palette.dim
        border.width: 1

        activeFocusOnTab: true
        Keys.onReturnPressed: button.activated()
        Keys.onEnterPressed: button.activated()
        Keys.onSpacePressed: button.activated()

        Text {
            id: buttonLabel
            anchors.centerIn: parent
            text: button.label
            color: root.shell.palette.fg
            font.family: Ui.Fonts.mono
            font.pixelSize: 12
        }

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.activated()
        }
    }
}
