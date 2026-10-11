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
        // Loader.item is typed QObject; the source exposes ids().
        return Model.workspaceIds(source.item ? source.item.ids(root.output) : []); // qmllint disable missing-property
    }

    function focusWorkspace(id) {
        Quickshell.execDetached(Ui.Compositor.focusWorkspace(id, root.output));
    }

    implicitWidth: workspaces.implicitWidth
    implicitHeight: workspaces.implicitHeight
    width: implicitWidth
    height: implicitHeight

    Loader {
        id: source
        source: Ui.Compositor.workspaceSource
    }

    Row {
        id: workspaces
        spacing: 2

        Repeater {
            model: source.item ? root.workspaceIds() : []

            delegate: Rectangle {
                required property int modelData

                readonly property bool occupied: source.item.occupied(modelData, root.output) // qmllint disable missing-property
                readonly property bool focused: source.item.activeId(root.output) === modelData // qmllint disable missing-property

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
