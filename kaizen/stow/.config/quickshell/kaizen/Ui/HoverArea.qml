import QtQuick

// A hovered MouseArea whose `pointed` fires once the pointer moves over it, not when the area appears or moves under a
// still pointer: a panel opening under the pointer, or rows rebuilt or scrolled under it, take no hover focus.
MouseArea {
    id: area

    // Where the pointer entered, in scene coordinates, which only the pointer's own motion changes.
    property point entry

    signal pointed

    hoverEnabled: true
    onEntered: area.entry = area.mapToItem(null, area.mouseX, area.mouseY)
    onPositionChanged: function (mouse) {
        const at = area.mapToItem(null, mouse.x, mouse.y);
        if (at.x !== area.entry.x || at.y !== area.entry.y)
            area.pointed();
    }
}
