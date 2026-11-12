import QtQuick

import "../../../Ui" as Ui

// The weather panel's bar button: the sky's icon, then the temperature once a forecast is in;
// while warnings stand (the panel's warning lines), an icon per event first, each in its level's
// colour.
Ui.BarButton {
    id: button

    required property var service

    implicitWidth: 58 * button.shell.textScale + button.prefixWidth
    prefix: button.service.alertGlyphs.map(glyph => ({
                icon: glyph.icon,
                color: button.shell.palette[glyph.level]
            }))
    label: button.service.ready ? button.service.icon + " " + button.service.temperature : button.service.icon
}
