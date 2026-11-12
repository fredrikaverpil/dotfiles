import QtQuick

import "../../../Ui" as Ui
import "../../services/firmware/FirmwareModel.js" as Model
import "../../../Ui/InfoTableModel.js" as Table

Column {
    id: root

    required property var shell
    // The firmware service, or the gallery's stand-in.
    required property var service

    // The id of the update whose command was copied last, until the panel closes.
    property string copied: ""

    readonly property int cardWidth: 400
    readonly property int cardHeight: implicitHeight + 2 * Ui.Space.cardPadding
    readonly property bool keyNavigation: true

    // One width for every group's table, so they line up.
    readonly property var tableWidths: Table.columnWidths(service.updates.map(update => Model.details(update)), 1, text => metrics.advanceWidth(text))
    // The copy button keeps its width when its label turns "Copied".
    readonly property int copyWidth: metrics.advanceWidth("Copy update command") + 24

    // Opening a release page hands over to the browser.
    signal closeRequested

    function copy(update) {
        if (root.service.copyCommand(update.id))
            root.copied = update.id;
    }

    function openPage(update) {
        if (root.service.openPage(update.id))
            root.closeRequested();
    }

    width: parent ? parent.width : 0
    spacing: 24

    Ui.PanelHeader {
        shell: root.shell
        title: "Firmware"
        subtitle: {
            const service = root.service;
            if (service.backends.length === 0)
                return "No firmware backend on this host";
            if (service.checking && service.lastChecked === 0)
                return "Checking…";
            const count = service.updates.length;
            const checked = service.lastChecked === 0 ? "" : " · checked " + Qt.formatDateTime(new Date(service.lastChecked), "HH:mm");
            if (count === 0 && service.errors.length > 0)
                return "Check failed" + checked;
            return (count === 0 ? "Up to date" : count + " pending") + checked;
        }
    }

    // The groups scroll under the fixed header.
    Ui.PanelScroller {
        visible: root.service.errors.length + root.service.updates.length > 0
        shell: root.shell

        // Above the updates: a backend whose check failed may be missing some.
        Ui.Section {
            visible: root.service.errors.length > 0
            shell: root.shell

            Repeater {
                model: root.service.errors

                delegate: Text {
                    required property var modelData

                    width: root.width
                    wrapMode: Text.WordWrap
                    color: root.shell.palette.rose
                    font.family: Ui.Fonts.mono
                    font.pixelSize: 14
                    text: modelData.backend + ": " + modelData.error
                }
            }
        }

        Repeater {
            model: root.service.updates

            delegate: UpdateGroup {
                required property var modelData
                update: modelData
            }
        }
    }

    FontMetrics {
        id: metrics
        font.family: Ui.Fonts.mono
        font.pixelSize: 14
    }

    // An update's facts, its release notes, then its buttons: the group's only focus stops.
    component UpdateGroup: Ui.Section {
        id: group

        required property var update

        shell: root.shell
        title: update.name

        Ui.InfoTable {
            shell: root.shell
            entries: Model.details(group.update)
            widths: root.tableWidths
        }

        Text {
            visible: group.update.notes !== ""
            width: root.width
            wrapMode: Text.WordWrap
            color: root.shell.palette.fg
            font.family: Ui.Fonts.mono
            font.pixelSize: 14
            text: group.update.notes
        }

        Item {
            width: root.width
            height: 8
        }

        Row {
            spacing: 8

            Ui.PanelButton {
                width: root.copyWidth
                shell: root.shell
                label: root.copied === group.update.id ? "Copied" : "Copy update command"
                onActivated: root.copy(group.update)
            }

            Ui.PanelButton {
                visible: group.update.url !== ""
                shell: root.shell
                label: "Open release page"
                onActivated: root.openPage(group.update)
            }
        }
    }
}
