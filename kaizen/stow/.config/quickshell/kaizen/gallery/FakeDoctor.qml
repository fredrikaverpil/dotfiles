import QtQuick

import "../modules/services/doctor/DoctorModel.js" as Model

// The doctor service's members the view reads, without `kaizen doctor`.
QtObject {
    id: fake

    readonly property real now: new Date(2026, 10, 12, 14, 2, 7).getTime()
    readonly property var shellWarning: ({
            source: "log",
            id: "log",
            level: "WARN",
            unit: "kaizen-shell",
            message: "WARN: attempted to insert into a list that no longer exists",
            count: 4,
            first: now - 12000,
            last: now - 12000
        })
    readonly property var devWarning: ({
            source: "check",
            id: "dev",
            level: "WARN",
            unit: "kaizen-shell",
            message: "runs /home/fredrik/.dotfiles/.claude/worktrees/kaizen-panel-design/kaizen/stow/.config/quickshell/kaizen",
            hint: "kaizen dev off",
            count: 1,
            first: now,
            last: now
        })
    readonly property var unitError: ({
            source: "check",
            id: "unit",
            level: "ERROR",
            unit: "kaizen-dcal",
            message: "failed: exited with status 1",
            hint: "systemctl --user restart kaizen-dcal",
            count: 1,
            first: now,
            last: now
        })
    readonly property var scenarios: ({
            "Healthy": {
                findings: [],
                text: "",
                checked: now,
                failure: "",
                running: false
            },
            "Warnings": {
                findings: [shellWarning, devWarning],
                text: "2 warnings\n\nWARN  kaizen-shell  ×4  14:01:55\n  WARN: attempted to insert into a list that no longer exists\nWARN  kaizen-shell  14:02:07\n  runs /home/fredrik/.dotfiles/.claude/worktrees/kaizen-panel-design/kaizen/stow/.config/quickshell/kaizen\n  hint: kaizen dev off",
                checked: now,
                failure: "",
                running: false
            },
            "Errors": {
                findings: [unitError, shellWarning],
                text: "1 error, 1 warning\n\nERROR kaizen-dcal  14:02:07\n  failed: exited with status 1\n  hint: systemctl --user restart kaizen-dcal\nWARN  kaizen-shell  ×4  14:01:55\n  WARN: attempted to insert into a list that no longer exists",
                checked: now,
                failure: "",
                running: false
            },
            "Checking": {
                findings: [],
                text: "",
                checked: 0,
                failure: "",
                running: true
            },
            "Failed": {
                findings: [],
                text: "",
                checked: 0,
                failure: "kaizen doctor: exited with 2",
                running: false
            }
        })

    property var findings: []
    property string text: ""
    property real checked: now
    property string failure: ""
    property bool running: false
    readonly property var counts: Model.counts(findings)

    function refresh() {
    }

    function copyAll() {
        return text !== "";
    }
}
