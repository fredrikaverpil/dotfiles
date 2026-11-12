import QtQuick

import "../../../Ui" as Ui

Column {
    id: root

    required property var shell
    required property var service

    readonly property var profileLabels: ({
            "power-saver": "󰌪 Saver",
            "balanced": "󰊚 Balanced",
            "performance": "󰓅 Performance"
        })
    readonly property color levelColor: shell.palette[service.chargeRole]

    readonly property int cardWidth: 400
    readonly property int cardHeight: implicitHeight + 2 * Ui.Space.cardPadding
    readonly property bool keyNavigation: true

    width: parent ? parent.width : 0
    spacing: 24

    Column {
        width: parent.width
        spacing: 16

        Ui.PanelHeader {
            shell: root.shell
            title: "Battery"
            subtitle: {
                if (!root.service.present)
                    return "No battery reported by UPower";
                if (root.service.stateLabel === "Holding")
                    return "Holding at " + root.service.threshold;
                const time = root.service.timeRemaining;
                if (time === "")
                    return root.service.stateLabel;
                return root.service.stateLabel + " · " + time + (root.service.onBattery ? " left" : " to full");
            }
        }

        Ui.PanelSlider {
            visible: root.service.present
            shell: root.shell
            interactive: false
            value: root.service.percentage / 100
            valueText: root.service.percentage + "%"
            icon: root.service.icon
            iconColor: root.levelColor
            fillColor: root.levelColor
        }
    }

    Ui.Section {
        visible: root.service.present
        shell: root.shell

        Ui.InfoTable {
            shell: root.shell
            entries: [
                {
                    label: root.service.onBattery ? "Draining" : "Charging",
                    value: root.service.rate
                },
                {
                    label: "Energy",
                    value: root.service.energy
                },
                {
                    label: "Health",
                    value: root.service.health
                },
                {
                    label: "Cycles",
                    value: root.service.cycles > 0 ? String(root.service.cycles) : "--"
                },
                {
                    label: "Charge limit",
                    value: root.service.threshold
                }
            ]
        }
    }

    Ui.Section {
        shell: root.shell
        title: "Power profile " + (root.service.onBattery ? "on battery" : "on AC")

        Ui.SegmentedControl {
            shell: root.shell
            options: root.service.profiles().map(name => ({
                        value: name,
                        label: root.profileLabels[name] || name
                    }))
            current: root.service.profile
            onPicked: value => root.service.setProfile(value)
        }
    }
}
