import QtQuick
import QtQuick.Controls
import QtQuick.Window
import Quickshell

import "../../../Ui" as Ui
import "../../services/network/NetworkModel.js" as Model
import "../../../Ui/InfoTableModel.js" as Table

Column {
    id: root

    required property var shell
    // The network service, or the gallery's stand-in.
    required property var service

    // Connection editing happens in nm-connection-editor; the panel closes for it.
    signal settingsRequested

    readonly property int cardWidth: 600
    readonly property int cardPadding: 16
    readonly property int cardHeight: implicitHeight + 2 * cardPadding
    readonly property bool keyNavigation: true
    // Past this, the groups scroll under a fixed header and footer.
    readonly property int maxBodyHeight: 520

    // One width for a row's main button, whatever its label, so names and buttons line up.
    readonly property int actionWidth: actionMetrics.advanceWidth + 24
    readonly property int forgetWidth: forgetMetrics.advanceWidth + 24

    // A device's details table.
    function detailRows(iface) {
        const m = Model.detailMetrics(root.service.detailsFor(iface));
        return [
            {
                label: "Interface",
                value: iface
            },
            {
                label: "IP address",
                value: m.ip
            },
            {
                label: "Ping (Cloudflare)",
                value: m.ping
            },
            {
                label: "Packet loss",
                value: m.loss
            },
            {
                label: "Ping (gateway)",
                value: m.gatewayPing
            },
            {
                label: "Packet loss",
                value: m.gatewayLoss
            },
            {
                label: "Receiving",
                value: m.receiving
            },
            {
                label: "Sending",
                value: m.sending
            },
            {
                label: "Downloaded",
                value: m.downloaded
            },
            {
                label: "Uploaded",
                value: m.uploaded
            },
            {
                label: "Gateway",
                value: m.gateway
            }
        ];
    }

    // Wired first, Wi-Fi last (Model.orderDevices).
    readonly property var devices: service.networkManagerAvailable ? Model.orderDevices(service.networkDevices, device => service.deviceTypeName(device)) : []
    readonly property int tablePerLine: 2
    // One set of column widths for every device's table, so they line up.
    readonly property var tableWidths: Table.columnWidths(devices.filter(device => device.connected).map(device => detailRows(device.name)), tablePerLine, text => tableMetrics.advanceWidth(text))

    readonly property bool hasWifiRows: service.wifiNetworks.length + service.outOfRangeWifi.length > 0

    width: parent ? parent.width : 0
    spacing: 24

    Ui.PanelHeader {
        shell: root.shell
        title: "Network"
        // The default route's device: its network, its type, or its iface when Quickshell does not
        // list it (a VPN's). Each card's own subnet still goes over that card.
        subtitle: {
            const service = root.service;
            if (!service.networkManagerAvailable)
                return "NetworkManager is unavailable";
            const iface = service.connection.iface;
            if (!iface)
                return root.devices.some(device => device.connected) ? "No default route" : "Disconnected";
            const device = service.networkDevices.find(candidate => candidate && candidate.name === iface);
            if (!device)
                return "Default route via " + iface;
            const type = service.deviceTypeName(device);
            return "Default route via " + (type === "Wi-Fi" && service.connectedWifiNetwork ? service.connectedWifiNetwork.name : type);
        }
    }

    // The groups scroll under a fixed header and footer, the bar in the card's right padding.
    Item {
        width: root.width
        implicitHeight: scroller.height

        // 16 wider than the content, so a row's `sel` fill reaching into the card's padding is not clipped.
        Flickable {
            id: scroller

            readonly property var focusedItem: scroller.Window.activeFocusItem

            function holds(item) {
                for (let candidate = item; candidate; candidate = candidate.parent)
                    if (candidate === body)
                        return true;
                return false;
            }

            // Only items in the body: focus outside it (the card, a view being replaced) scrolls nothing.
            // Map to content coordinates: Flickable coordinates are relative to its viewport.
            onFocusedItemChanged: {
                const item = focusedItem;
                if (!item || !visible || !holds(item))
                    return;
                // Focus in the Wi-Fi list holds its order, as a pointer over it does.
                for (let candidate = item; candidate; candidate = candidate.parent)
                    if (candidate.objectName === "wifiList")
                        root.service.freezeOrder();
                const top = item.mapToItem(body, 0, 0).y;
                if (top < contentY)
                    contentY = Math.max(0, top);
                else if (top + item.height > contentY + height)
                    contentY = top + item.height - height;
            }

            x: -8
            width: root.width + 16
            height: Math.min(body.implicitHeight, root.maxBodyHeight)
            contentWidth: width
            contentHeight: body.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: scrollBar

            Column {
                id: body

                x: 8
                width: root.width
                spacing: 24

                Repeater {
                    // ScriptModel diffs by identity: a reorder moves groups, keeping a passphrase being typed.
                    model: ScriptModel {
                        values: root.devices
                    }

                    delegate: DeviceGroup {
                        required property var modelData
                        device: modelData
                    }
                }

                Text {
                    visible: root.service.networkManagerAvailable && root.service.networkDevices.length === 0
                    color: root.shell.palette.off
                    font.family: Ui.Fonts.mono
                    font.pixelSize: 14
                    text: "No network devices"
                }
            }
        }

        Ui.PanelScrollBar {
            id: scrollBar
            x: root.width + 10
            height: scroller.height
            shell: root.shell
        }
    }

    Ui.PanelFooter {
        shell: root.shell

        Ui.PanelButton {
            visible: root.service.networkManagerAvailable
            shell: root.shell
            label: "Connection settings…"
            onActivated: root.settingsRequested()
        }
    }

    FontMetrics {
        id: tableMetrics
        font.family: Ui.Fonts.mono
        font.pixelSize: 14
    }

    TextMetrics {
        id: actionMetrics
        font.family: Ui.Fonts.mono
        font.pixelSize: 14
        text: "Disconnect"
    }

    TextMetrics {
        id: forgetMetrics
        font.family: Ui.Fonts.mono
        font.pixelSize: 14
        text: "Forget"
    }

    // A device's group: its details while connected; for Wi-Fi, its power button at the label's right
    // and the networks under the details.
    component DeviceGroup: Ui.Section {
        id: group

        required property var device
        readonly property bool wifi: root.service.deviceTypeName(device) === "Wi-Fi"

        shell: root.shell
        title: root.service.deviceTypeName(device)
        control: wifi ? powerButton : null

        Component {
            id: powerButton

            Ui.PanelButton {
                width: root.actionWidth
                shell: root.shell
                label: root.service.wifiEnabled ? "Turn off" : "Turn on"
                onActivated: root.service.toggleWifi()
            }
        }

        Ui.InfoTable {
            visible: group.device.connected
            shell: root.shell
            perLine: root.tablePerLine
            widths: root.tableWidths
            entries: group.device.connected ? root.detailRows(group.device.name) : []
        }

        // Wi-Fi's state shows in its network rows instead.
        Item {
            width: root.width
            implicitHeight: stateText.implicitHeight
            visible: !group.device.connected && !group.wifi

            Text {
                id: stateText
                color: root.shell.palette.off
                font.family: Ui.Fonts.mono
                font.pixelSize: 14
                text: root.service.deviceState(group.device)
            }

            Text {
                anchors.right: parent.right
                color: root.shell.palette.off
                font.family: Ui.Fonts.mono
                font.pixelSize: 14
                text: group.device.name
            }
        }

        Column {
            objectName: "wifiList"
            visible: group.wifi
            width: root.width
            spacing: 4

            // A pointer over the list holds its order, so a scan never moves a row under it.
            HoverHandler {
                onHoveredChanged: if (hovered)
                    root.service.freezeOrder()
            }

            Text {
                visible: !root.hasWifiRows
                color: root.shell.palette.off
                font.family: Ui.Fonts.mono
                font.pixelSize: 14
                text: !root.service.wifiEnabled ? "Wi-Fi is off" : root.service.scanning ? "Scanning…" : "No networks found"
            }

            Repeater {
                // ScriptModel diffs by identity, keeping delegates (and a passphrase being typed) alive.
                model: ScriptModel {
                    values: group.wifi ? root.service.wifiNetworks : []
                }

                delegate: WifiRow {
                    required property var modelData
                    network: modelData
                }
            }

            Repeater {
                model: ScriptModel {
                    values: group.wifi ? root.service.outOfRangeWifi : []
                    objectProp: "uuid"
                }

                delegate: SavedRow {
                    required property var modelData
                    saved: modelData
                }
            }
        }
    }

    // A network in range: its buttons are the focus stops; the row itself takes no focus.
    component WifiRow: Column {
        id: wifiRow

        required property var network
        readonly property string action: root.service.wifiAction(network)
        readonly property string status: root.service.wifiStatus(network)
        // "Connecting…", "Disconnecting…", "Forgetting…".
        readonly property bool changing: status.endsWith("…")
        readonly property bool forgettable: Model.canForgetNetwork(network)

        function activate() {
            root.service.freezeOrder();
            if (action !== "" && !root.service.busy)
                root.service.activate(network);
        }

        function forget() {
            if (forgettable && !root.service.busy)
                root.service.forget(network.name);
        }

        width: root.width
        spacing: 4

        Item {
            id: line
            width: parent.width
            implicitHeight: 28

            Text {
                id: wifiIcon
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 16
                horizontalAlignment: Text.AlignHCenter
                color: wifiRow.network.connected ? root.shell.palette.leaf : root.shell.palette.off
                font.family: Ui.Fonts.mono
                font.pixelSize: 14
                text: Model.wifiIconFor(Model.wifiSignal(wifiRow.network))
            }

            Text {
                anchors.left: wifiIcon.right
                anchors.leftMargin: 8
                anchors.right: statusText.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                color: root.shell.palette.fg
                font.family: Ui.Fonts.mono
                font.pixelSize: 14
                text: wifiRow.network.name
            }

            Text {
                id: statusText
                anchors.right: lockText.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                color: root.shell.palette.sky
                font.family: Ui.Fonts.mono
                font.pixelSize: 14
                text: wifiRow.changing ? wifiRow.status : ""
            }

            Text {
                id: lockText
                anchors.right: forgetSlot.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 16
                horizontalAlignment: Text.AlignHCenter
                color: root.shell.palette.off
                font.family: Ui.Fonts.mono
                font.pixelSize: 14
                text: root.service.wifiSecured(wifiRow.network) ? "󰌾" : ""
            }

            Item {
                id: forgetSlot
                anchors.right: actionSlot.left
                anchors.rightMargin: 8
                width: root.forgetWidth
                height: parent.height

                Ui.PanelButton {
                    anchors.fill: parent
                    visible: wifiRow.forgettable
                    shell: root.shell
                    label: "Forget"
                    onActivated: wifiRow.forget()
                }
            }

            Item {
                id: actionSlot
                anchors.right: parent.right
                width: root.actionWidth
                height: parent.height

                Ui.PanelButton {
                    anchors.fill: parent
                    visible: wifiRow.action !== ""
                    shell: root.shell
                    label: wifiRow.action
                    onActivated: wifiRow.activate()
                }
            }
        }

        Item {
            width: parent.width
            height: 28
            visible: root.service.passwordSsid === wifiRow.network.name
            // Focus scrolls the field into view; it can open below the fold.
            onVisibleChanged: if (visible)
                passphrase.forceActiveFocus()

            TextField {
                id: passphrase
                anchors.left: parent.left
                anchors.right: join.left
                anchors.rightMargin: 8
                height: parent.height
                color: root.shell.palette.fg
                font.family: Ui.Fonts.mono
                font.pixelSize: 14
                placeholderText: "Passphrase"
                placeholderTextColor: root.shell.palette.off
                echoMode: TextInput.Password
                selectByMouse: true
                background: Rectangle {
                    radius: 4
                    color: passphrase.activeFocus ? root.shell.palette.sel : "transparent"
                    border.color: root.shell.palette.dim
                    border.width: 1
                }
                onAccepted: if (text.length > 0)
                    root.service.connectWithPassphrase(wifiRow.network.name, text)
            }

            Ui.PanelButton {
                id: join
                anchors.right: parent.right
                width: root.actionWidth
                shell: root.shell
                label: "Join"
                onActivated: if (passphrase.text.length > 0)
                    root.service.connectWithPassphrase(wifiRow.network.name, passphrase.text)
            }
        }

        Text {
            width: parent.width
            visible: text !== ""
            color: root.shell.palette.rose
            font.family: Ui.Fonts.mono
            font.pixelSize: 14
            text: root.service.failureSsid === wifiRow.network.name ? root.service.failureReason : ""
        }
    }

    // A saved network out of range: its Forget button forgets it.
    component SavedRow: Item {
        id: savedRow

        required property var saved

        function forget() {
            if (!root.service.busy)
                root.service.forgetSaved(saved.uuid);
        }

        width: root.width
        implicitHeight: 28

        Text {
            id: savedIcon
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            horizontalAlignment: Text.AlignHCenter
            color: root.shell.palette.off
            font.family: Ui.Fonts.mono
            font.pixelSize: 14
            text: "󰤮"
        }

        Text {
            anchors.left: savedIcon.right
            anchors.leftMargin: 8
            anchors.right: rangeText.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            color: root.shell.palette.off
            font.family: Ui.Fonts.mono
            font.pixelSize: 14
            text: savedRow.saved.ssid
        }

        Text {
            id: rangeText
            anchors.right: savedForget.left
            anchors.rightMargin: 8 + 16 + 8
            anchors.verticalCenter: parent.verticalCenter
            color: root.shell.palette.off
            font.family: Ui.Fonts.mono
            font.pixelSize: 14
            text: "Out of range"
        }

        Ui.PanelButton {
            id: savedForget
            anchors.right: parent.right
            anchors.rightMargin: root.actionWidth + 8
            width: root.forgetWidth
            shell: root.shell
            label: "Forget"
            onActivated: savedRow.forget()
        }
    }
}
