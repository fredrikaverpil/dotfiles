import QtQuick
import Quickshell.Io

import "UmbrielPin.js" as Model

QtObject {
    id: root

    property string appId
    property var windowId: 0

    property Process stream: Process {
        running: root.appId !== ""
        command: ["umbriel", "subscribe", "windows"]
        stdout: SplitParser {
            onRead: function (line) {
                root.windowId = Model.windowId(line, root.appId, root.windowId);
            }
        }
    }
}
