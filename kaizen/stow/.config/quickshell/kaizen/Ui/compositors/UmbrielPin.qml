import QtQuick

import "UmbrielPin.js" as Model

QtObject {
    // UmbrielEvents.
    property var events: null
    property string appId
    readonly property var windowId: events ? Model.windowId(events.windows, appId) : 0
}
