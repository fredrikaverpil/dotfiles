import QtQuick

import "../../../Ui" as Ui

Column {
    id: root

    required property var shell
    // The bluetooth service.
    required property var service

    // Pairing, forgetting and the rest happen in bluetui; the panel closes for it.
    signal settingsRequested

    readonly property int cardWidth: 400
    readonly property int cardHeight: implicitHeight + 2 * Ui.Space.cardPadding
    // One width for a row's button, whatever its label, so the statuses line up.
    readonly property int actionWidth: actionMetrics.advanceWidth + 24
    readonly property bool keyNavigation: true

    width: parent ? parent.width : 0
    spacing: 24

    // The power button sits where a key value would: it is the panel's key state.
    Item {
        width: parent.width
        implicitHeight: Math.max(header.implicitHeight, power.height)

        Ui.PanelHeader {
            id: header
            width: parent.width - (power.visible ? power.width + 8 : 0)
            shell: root.shell
            title: "Bluetooth"
            subtitle: {
                const service = root.service;
                if (!service.available)
                    return "No Bluetooth adapter";
                if (!service.powered)
                    return "Off";
                if (service.devices.length === 0)
                    return "No paired devices";
                return service.connectedCount > 0 ? service.connectedCount + " connected" : "None connected";
            }
        }

        Ui.PanelButton {
            id: power
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            // As wide for either label, so the button keeps its place.
            width: powerMetrics.advanceWidth + 24
            visible: root.service.available
            shell: root.shell
            label: root.service.powered ? "Turn off" : "Turn on"
            onActivated: root.service.togglePower()
        }

        TextMetrics {
            id: powerMetrics
            font.family: Ui.Fonts.mono
            font.pixelSize: 14
            text: "Turn off"
        }
    }

    Ui.Section {
        visible: root.service.powered && root.service.devices.length > 0
        shell: root.shell
        title: "Paired devices"

        Column {
            width: parent.width
            spacing: 4

            Repeater {
                model: root.service.powered ? root.service.devices : []

                delegate: DeviceRow {
                    required property var modelData
                    device: modelData
                }
            }
        }
    }

    // A hidden footer's button never shows again, so the footer hides, not the button.
    Ui.PanelFooter {
        visible: root.service.available
        shell: root.shell

        Ui.PanelButton {
            shell: root.shell
            label: "Bluetooth settings…"
            onActivated: root.settingsRequested()
        }
    }

    // A paired device: its button connects or disconnects it; the row takes no focus.
    component DeviceRow: Item {
        id: row

        required property var device
        // Empty while connecting or disconnecting.
        readonly property string action: root.service.deviceAction(device)
        readonly property bool busy: action === ""
        // The action the button showed before the change began, kept while it runs.
        property string shownAction

        Binding on shownAction {
            when: !row.busy
            value: row.action
            restoreMode: Binding.RestoreNone
        }
        // Percent, or negative when not shown.
        readonly property int battery: device.connected ? Math.round(root.service.battery(device) * 100) : -1

        function toggle() {
            if (!busy)
                root.service.toggleConnection(device);
        }

        width: root.width
        implicitHeight: 28

        Text {
            id: icon
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            // Glyphs differ in width; a column keeps the names aligned.
            width: 16
            horizontalAlignment: Text.AlignHCenter
            color: row.device.connected ? root.shell.palette.leaf : root.shell.palette.off
            font.family: Ui.Fonts.mono
            font.pixelSize: 14
            text: root.service.deviceIcon(row.device)
        }

        Text {
            anchors.left: icon.right
            anchors.leftMargin: 8
            anchors.right: statusText.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            color: root.shell.palette.fg
            font.family: Ui.Fonts.mono
            font.pixelSize: 14
            text: row.device.name || row.device.address
        }

        Text {
            id: statusText
            anchors.right: actionButton.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            color: row.busy ? root.shell.palette.sky : root.shell.palette[root.shell.batteryService.levelRole(row.battery)]
            font.family: Ui.Fonts.mono
            font.pixelSize: 14
            text: row.busy ? root.service.deviceStatus(row.device) : row.battery >= 0 ? row.battery + "%" : ""
        }

        // Inactive while connecting, so it keeps its focus and the status does not shift.
        Ui.PanelButton {
            id: actionButton
            anchors.right: parent.right
            width: root.actionWidth
            height: parent.height
            available: !row.busy
            shell: root.shell
            label: row.shownAction
            onActivated: row.toggle()
        }
    }

    TextMetrics {
        id: actionMetrics
        font.family: Ui.Fonts.mono
        font.pixelSize: 14
        text: "Disconnect"
    }
}
