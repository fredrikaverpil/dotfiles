import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell

import "../../../Ui" as Ui
import "../NotificationLogic.js" as NotificationLogic

Rectangle {
    id: root

    required property var palette // qmllint disable property-override
    property var row: ({})
    property var notification: null
    property bool toast: false
    property bool selectable: false
    property bool selected: false
    property int selectedButton: -1
    property int duration: 0
    property bool hovered: hoverHandler.hovered
    property real remaining: 1.0

    signal closeRequested
    signal invokeRequested
    signal actionRequested(var action)
    signal expired

    readonly property string app: String(row.app || "")
    readonly property string appIcon: String(row.appIcon || "")
    readonly property string summary: String(row.summary || "")
    readonly property string body: String(row.body || "")
    readonly property string image: String(row.image || "")
    readonly property string ruleIcon: String(row.icon || "")
    readonly property string ruleBadge: String(row.badge || "")
    readonly property real perimeter: 2 * (width + height)
    readonly property int urgency: Number(row.urgency)
    readonly property var buttons: notification ? NotificationLogic.buttons(notification.actions, row.actions) : []
    readonly property color accent: urgency === 2 ? palette.rose : (urgency === 0 ? palette.off : palette.fg)
    // A rule's border colour takes the place of the urgency's.
    readonly property color tint: palette[String(row.border || "")] ?? accent
    readonly property bool orbiting: toast && row.borderAnimation === "orbit"
    readonly property bool beating: toast && row.borderAnimation === "heartbeat"
    // A rule's icon takes the notification's place, which moves to the badge
    // unless the rule sets its own.
    readonly property string icon: ruleIcon || ownIcon
    readonly property string badge: ruleBadge || (ruleIcon ? ownIcon : "")
    readonly property string ownIcon: {
        if (image)
            return image;
        if (!appIcon)
            return "";
        if (appIcon.indexOf("file://") === 0 || appIcon.indexOf("image://") === 0)
            return appIcon;
        if (appIcon.charAt(0) === "/")
            return "file://" + appIcon;
        return Quickshell.iconPath(appIcon, true);
    }

    width: 400
    implicitHeight: content.implicitHeight + 24
    radius: 8
    color: activeFocus || selected ? palette.sel : palette.bg
    border.color: tint
    border.width: 1
    clip: true

    activeFocusOnTab: selectable
    Keys.onPressed: function (event) {
        if (!root.selectable || event.key !== Qt.Key_Backspace)
            return;
        root.closeRequested();
        event.accepted = true;
    }

    HoverHandler {
        id: hoverHandler
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: function (mouse) {
            if (mouse.button === Qt.RightButton)
                root.closeRequested();
            else
                root.invokeRequested();
        }
    }

    // A thicker dash on the border, travelling its perimeter. Dash and gap are in
    // stroke widths; the gap exceeds the perimeter, so the dash laps alone, with a pause.
    // The lap is timed by the wall clock, so every orbiting toast laps in step.
    Shape {
        id: orbit
        readonly property real thickness: 3
        readonly property real dash: 56 / thickness
        readonly property real period: dash + (root.perimeter + 300) / thickness
        readonly property int lap: 3600
        anchors.fill: parent
        visible: root.orbiting
        layer.enabled: visible
        layer.samples: 4

        ShapePath {
            id: orbitPath
            strokeColor: root.tint
            strokeWidth: orbit.thickness
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            strokeStyle: ShapePath.DashLine
            dashPattern: [orbit.dash, orbit.period - orbit.dash]

            PathRectangle {
                x: 1.5
                y: 1.5
                width: root.width - 3
                height: root.height - 3
                radius: 6.5
            }
        }

        FrameAnimation {
            running: orbit.visible
            onTriggered: orbitPath.dashOffset = -(Date.now() % orbit.lap) / orbit.lap * orbit.period
        }
    }

    // A thicker border fading in and out on the heartbeat. Timed by the wall
    // clock, so every beating toast beats in step.
    Rectangle {
        id: heartbeat
        anchors.fill: parent
        visible: root.beating
        radius: root.radius
        color: "transparent"
        border.color: root.tint
        border.width: 3

        FrameAnimation {
            running: heartbeat.visible
            onTriggered: heartbeat.opacity = NotificationLogic.heartbeat(Date.now())
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

                // Ringed in the card's colour to set it apart from the icon.
                Rectangle {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: -5
                    width: 22
                    height: 22
                    radius: 11
                    color: root.color
                    visible: root.badge.length > 0 && badgeImage.status !== Image.Error

                    Image {
                        id: badgeImage
                        anchors.fill: parent
                        anchors.margins: 2
                        source: root.badge
                        sourceSize.width: 36
                        sourceSize.height: 36
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Text {
                    Layout.fillWidth: true
                    text: root.summary || root.app
                    textFormat: Text.PlainText
                    color: root.palette.fg
                    font.family: Ui.Fonts.mono
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
                    font.family: Ui.Fonts.mono
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
                    font.family: Ui.Fonts.mono
                    font.pixelSize: 11
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
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
            visible: root.buttons.length > 0
            spacing: 6

            Repeater {
                model: root.buttons

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    implicitWidth: actionLabel.implicitWidth + 16
                    implicitHeight: 26
                    radius: 4
                    color: actionArea.containsMouse ? root.palette.sel : "transparent"
                    border.color: index === root.selectedButton ? root.palette.fg : root.palette.dim
                    border.width: 1

                    Text {
                        id: actionLabel
                        anchors.centerIn: parent
                        text: modelData.text
                        textFormat: Text.PlainText
                        color: root.palette.fg
                        font.family: Ui.Fonts.mono
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

    // Aligned with the content, centered in the bottom padding.
    Rectangle {
        anchors.left: content.left
        anchors.bottom: parent.bottom
        anchors.bottomMargin: (content.anchors.bottomMargin - height) / 2
        width: content.width * root.remaining
        height: root.toast && root.duration > 0 ? 2 : 0
        color: root.tint
    }

    Timer {
        interval: 50
        repeat: true
        running: root.toast && root.duration > 0 && !root.hovered && !root.selected
        onTriggered: {
            root.remaining -= interval / root.duration;
            if (root.remaining <= 0) {
                root.remaining = 0;
                root.expired();
            }
        }
    }
}
