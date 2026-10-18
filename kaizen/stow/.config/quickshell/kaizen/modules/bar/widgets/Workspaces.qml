import QtQuick
import Quickshell

import "../../../Ui" as Ui
import "WorkspaceModel.js" as Model

Item {
    id: root

    required property string output
    required property color foreground
    required property color selection
    property real fontScale: 1

    function workspaceIds() {
        return Model.workspaceIds(Ui.Compositor.workspaces ? Ui.Compositor.workspaces.ids(root.output) : []);
    }

    function focusWorkspace(id) {
        Quickshell.execDetached(Ui.Compositor.focusWorkspace(id, root.output));
    }

    implicitWidth: workspaces.implicitWidth
    implicitHeight: workspaces.implicitHeight
    width: implicitWidth
    height: implicitHeight

    Row {
        id: workspaces
        spacing: 2

        Repeater {
            model: Ui.Compositor.workspaces ? root.workspaceIds() : []

            delegate: Rectangle {
                required property int modelData

                readonly property bool occupied: Ui.Compositor.workspaces.occupied(modelData, root.output)
                readonly property bool focused: Ui.Compositor.workspaces.activeId(root.output) === modelData

                width: 20 * root.fontScale
                height: Math.round(24 * root.fontScale)
                radius: 4
                color: hover.hovered ? root.selection : "transparent"
                opacity: occupied || focused ? 1 : 0.5
                border.width: focused ? 1 : 0
                border.color: root.foreground

                Text {
                    anchors.centerIn: parent
                    color: root.foreground
                    font.family: Ui.Fonts.mono
                    font.pixelSize: 14 * root.fontScale
                    text: modelData === 10 ? "0" : String(modelData)
                }

                HoverHandler {
                    id: hover
                }

                // Not a MouseArea, for the reason in Ui/BarButton.qml.
                TapHandler {
                    onTapped: root.focusWorkspace(modelData)
                }
            }
        }
    }
}
