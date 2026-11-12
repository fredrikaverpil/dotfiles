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
    readonly property var niriError: ({
            source: "check",
            id: "niri-config",
            level: "ERROR",
            unit: "niri",
            message: "niri validate:\nError: unexpected node `focus-ring-colour`\n  at ~/.config/niri/config.kdl:42:5",
            count: 1,
            first: now,
            last: now
        })
    // Log findings over a span, one per unit.
    function logWarning(unit, message, count) {
        return {
            source: "log",
            id: "log",
            level: "WARN",
            unit: unit,
            message: message,
            count: count,
            first: now - 3600000,
            last: now - 60000
        };
    }
    readonly property var many: [unitError, niriError, shellWarning, devWarning, logWarning("kaizen-dcal", "sync: calendar \"Work\" timed out after 30 s", 12), logWarning("kaizen-investigator", "slog: run 41 exited with status 2", 3), logWarning("kaizen-sleep-lock", "inhibitor taken late: 812 ms", 2), logWarning("kaizen-tray-ready", "StatusNotifierWatcher not on the bus after 5 s", 1), logWarning("kaizen-mirror-DP-1", "wl-mirror: output DP-1 went away", 2), logWarning("kaizen-gcloud-auth", "token refresh failed: invalid_grant", 6)]
    readonly property var scenarios: ({
            "Healthy": {
                findings: [],
                text: "No errors or warnings",
                checked: now,
                failure: "",
                running: false
            },
            "Warnings": {
                findings: [shellWarning, devWarning],
                text: "2 warnings\n\nWARN  kaizen-shell  ×4  14:01:55\n  WARN: attempted to insert into a list that no longer exists\nWARN  kaizen-shell  check\n  runs /home/fredrik/.dotfiles/.claude/worktrees/kaizen-panel-design/kaizen/stow/.config/quickshell/kaizen\n  hint: kaizen dev off",
                checked: now,
                failure: "",
                running: false
            },
            "Errors": {
                findings: [unitError, shellWarning],
                text: "1 error, 1 warning\n\nERROR kaizen-dcal  check\n  failed: exited with status 1\n  hint: systemctl --user restart kaizen-dcal\nWARN  kaizen-shell  ×4  14:01:55\n  WARN: attempted to insert into a list that no longer exists",
                checked: now,
                failure: "",
                running: false
            },
            "Many": {
                findings: many,
                text: "2 errors, 8 warnings\n\n…",
                checked: now,
                failure: "",
                running: false
            },
            "Failed with findings": {
                findings: [unitError, shellWarning],
                text: "1 error, 1 warning\n\n…",
                checked: now - 120000,
                failure: "kaizen doctor: journalctl: Failed to get journal access",
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

    function copyFinding(finding) {
    }
}
