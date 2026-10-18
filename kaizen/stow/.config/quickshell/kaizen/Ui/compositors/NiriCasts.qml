import QtQuick

import "NiriCasts.js" as Model

QtObject {
    // NiriEvents.
    property var events: null
    readonly property bool sharing: events ? Model.sharing(events.casts) : false
}
