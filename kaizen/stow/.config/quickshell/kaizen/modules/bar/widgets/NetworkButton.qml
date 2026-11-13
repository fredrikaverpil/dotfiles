import QtQuick

import "../../../Ui" as Ui

// The network panel's bar button: rose while disconnected, with the Wi-Fi network's name.
Ui.BarButton {
    id: button

    required property var service

    readonly property string ssid: button.service.kind === "wifi" && button.service.connectedWifiNetwork ? button.service.connectedWifiNetwork.name : ""

    foreground: button.service.kind === "disconnected" ? button.shell.palette.rose : button.shell.palette.fg
    // At most 16 characters; the panel shows the full name.
    label: button.service.icon + (ssid ? " " + (ssid.length > 16 ? ssid.slice(0, 15) + "…" : ssid) : "")
}
