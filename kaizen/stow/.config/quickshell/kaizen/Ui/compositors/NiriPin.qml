import QtQuick
import Quickshell

import "NiriPin.js" as Model

QtObject {
    id: root

    // NiriEvents.
    property var events: null
    property string appId
    readonly property var windowId: events ? Model.windowId(events.windows, appId) : 0
    // The height last asked for; see Model.follow.
    property int requested: 0

    onWindowIdChanged: requested = 0

    property Connections listener: Connections {
        target: root.events
        function onReceived(event) {
            var result = Model.follow(event, root.windowId, root.events.workspaces, root.requested);
            root.requested = result.requested;
            if (result.command)
                Quickshell.execDetached(result.command);
        }
    }
}
