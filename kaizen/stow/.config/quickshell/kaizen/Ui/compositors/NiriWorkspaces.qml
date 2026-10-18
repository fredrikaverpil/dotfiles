import QtQuick

import "NiriWorkspaces.js" as Model

QtObject {
    id: root

    // NiriEvents.
    property var events: null
    readonly property var workspaces: events ? events.workspaces : ({})
    readonly property var windowCounts: Model.windowCounts(events ? events.windows : ({}))

    function ids(output) {
        return Model.ids(workspaces, output);
    }
    function activeId(output) {
        return Model.activeId(workspaces, output);
    }
    function occupied(idx, output) {
        return Model.occupied(workspaces, windowCounts, output, idx);
    }
}
