import QtQuick
import Quickshell
import Quickshell.Io

import "NiriPin.js" as Model

QtObject {
    id: root

    property string appId
    property var state: ({
            id: 0,
            requested: 0,
            spaces: ({})
        })
    readonly property var windowId: state.id

    property Process stream: Process {
        running: root.appId !== ""
        command: ["niri", "msg", "-j", "event-stream"]
        stdout: SplitParser {
            onRead: function (line) {
                root.state = Model.follow(line, root.appId, root.state);
                if (root.state.command)
                    Quickshell.execDetached(root.state.command);
            }
        }
    }
}
