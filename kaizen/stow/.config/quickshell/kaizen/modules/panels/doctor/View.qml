import QtQuick

import "../../../Ui" as Ui
import "../../services/doctor/DoctorModel.js" as Model
import "../../../Ui/Time.js" as Time

Column {
    id: root

    required property var shell
    // The doctor service, or the gallery's stand-in.
    required property var service

    // What was copied last, until the panel closes: "all", or a finding's `Model.key`.
    property string copied: ""
    // The focused finding's `Model.key`, so focus survives a run, which rebuilds the rows; "" off the rows.
    property string focusedKey: ""

    readonly property int cardWidth: 600
    readonly property int cardHeight: implicitHeight + 2 * Ui.Space.cardPadding
    readonly property bool keyNavigation: true

    function reset() {
        Qt.callLater(() => {
            const first = rows.itemAt(0);
            if (first)
                first.forceActiveFocus();
        });
    }

    function copyAll() {
        if (root.service.copyAll())
            root.copied = "all";
    }

    function copy(finding) {
        root.service.copyFinding(finding);
        root.copied = Model.key(finding);
    }

    width: parent ? parent.width : 0
    spacing: 24

    Ui.PanelHeader {
        shell: root.shell
        title: "Doctor"
        subtitle: {
            const service = root.service;
            if (service.checked === 0)
                return service.running ? "Checking…" : "Check failed";
            const counts = service.findings.length === 0 ? "No errors or warnings" : Model.summary(service.counts);
            return counts + " · checked " + Time.stamp(new Date(service.checked), new Date());
        }
    }

    // The findings scroll under the fixed header.
    Ui.PanelScroller {
        visible: root.service.failure !== "" || root.service.findings.length > 0
        shell: root.shell

        // Above the findings: they are from the last run that gave a report.
        Ui.Section {
            visible: root.service.failure !== ""
            shell: root.shell

            Text {
                width: root.width
                wrapMode: Text.Wrap
                color: root.shell.palette.rose
                font.family: Ui.Fonts.mono
                font.pixelSize: 14
                textFormat: Text.PlainText
                text: root.service.failure
            }
        }

        Ui.Section {
            visible: root.service.findings.length > 0
            shell: root.shell

            Column {
                width: root.width
                spacing: 4

                Repeater {
                    id: rows
                    model: root.service.findings

                    delegate: FindingRow {
                        required property var modelData
                        finding: modelData
                    }
                }
            }
        }
    }

    // A healthy report says only that.
    Ui.PanelFooter {
        visible: root.service.findings.length > 0
        shell: root.shell

        Ui.PanelButton {
            // As wide for either label, so the button keeps its place.
            width: metrics.advanceWidth("Copy report") + 24
            shell: root.shell
            label: root.copied === "all" ? "Copied" : "Copy report"
            onActiveFocusChanged: if (activeFocus)
                root.focusedKey = ""
            onActivated: root.copyAll()
        }
    }

    FontMetrics {
        id: metrics
        font.family: Ui.Fonts.mono
        font.pixelSize: 14
    }

    // A finding: its level and unit, when it happened, its message and its fix. Enter, Space or a click copies it.
    component FindingRow: Item {
        id: row

        required property var finding
        readonly property string key: Model.key(finding)
        readonly property bool copied: root.copied === key

        width: root.width
        implicitHeight: lines.implicitHeight + 10
        activeFocusOnTab: true
        onActiveFocusChanged: if (activeFocus)
            root.focusedKey = key
        Component.onCompleted: if (key === root.focusedKey)
            Qt.callLater(() => row.forceActiveFocus())

        Keys.onReturnPressed: root.copy(row.finding)
        Keys.onEnterPressed: root.copy(row.finding)
        Keys.onSpacePressed: root.copy(row.finding)

        // The fill reaches into the card's padding, so the text aligns with the rule.
        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: -8
            anchors.rightMargin: -8
            radius: 4
            color: row.activeFocus || mouse.containsMouse ? root.shell.palette.sel : "transparent"
        }

        Column {
            id: lines

            y: 5
            width: parent.width
            spacing: 4

            Item {
                width: parent.width
                height: level.implicitHeight

                Text {
                    id: level
                    color: root.shell.palette[Model.role(row.finding.level)]
                    font.family: Ui.Fonts.mono
                    font.pixelSize: 14
                    text: row.finding.level === "WARN" ? "Warning" : "Error"
                }

                Text {
                    anchors.left: level.right
                    anchors.leftMargin: 8
                    anchors.right: when.left
                    anchors.rightMargin: when.text ? 8 : 0
                    elide: Text.ElideRight
                    color: root.shell.palette.fg
                    font.family: Ui.Fonts.mono
                    font.pixelSize: 14
                    textFormat: Text.PlainText
                    text: row.finding.unit
                }

                Text {
                    id: when
                    anchors.right: parent.right
                    color: row.copied ? root.shell.palette.leaf : root.shell.palette.off
                    font.family: Ui.Fonts.mono
                    font.pixelSize: 14
                    text: row.copied ? "Copied" : Model.when(row.finding, new Date())
                }
            }

            Text {
                width: parent.width
                wrapMode: Text.Wrap
                color: root.shell.palette.fg
                font.family: Ui.Fonts.mono
                font.pixelSize: 14
                textFormat: Text.PlainText
                text: row.finding.message
            }

            Text {
                visible: !!row.finding.hint
                width: parent.width
                wrapMode: Text.Wrap
                color: root.shell.palette.off
                font.family: Ui.Fonts.mono
                font.pixelSize: 14
                textFormat: Text.PlainText
                text: row.finding.hint || ""
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            anchors.leftMargin: -8
            anchors.rightMargin: -8
            hoverEnabled: true
            onClicked: root.copy(row.finding)
        }
    }
}
