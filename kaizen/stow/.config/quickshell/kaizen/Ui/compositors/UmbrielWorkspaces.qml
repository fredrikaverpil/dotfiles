import QtQuick

import "UmbrielWorkspaces.js" as Model

QtObject {
    id: root

    // UmbrielEvents.
    property var events: null
    readonly property var workspaces: events ? events.workspaces : []

    function ids(output) {
        return Model.ids(workspaces, output);
    }
    function activeId(output) {
        return Model.activeId(workspaces, output);
    }
    function occupied(idx, output) {
        return Model.occupied(workspaces, output, idx);
    }
}
