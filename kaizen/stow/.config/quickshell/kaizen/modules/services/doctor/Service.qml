import QtQuick
import Quickshell
import Quickshell.Io

import "DoctorModel.js" as Model

// What `kaizen doctor` reports: the kaizen units' warnings and errors from
// their current runs, and what is out of order.
Item {
    id: root

    // From the last run that gave a report.
    property var findings: []
    property string text: ""
    // Milliseconds since the epoch; 0 before the first report.
    property real checked: 0
    // Why the last run gave no report; "" when it did.
    property string failure: ""
    readonly property var counts: Model.counts(findings)
    readonly property bool running: doctor.running

    function refresh() {
        if (!doctor.running)
            doctor.start();
    }

    function copyAll() {
        if (text === "")
            return false;
        Quickshell.execDetached(["wl-copy", "--", text]);
        return true;
    }

    function status() {
        return JSON.stringify({
            errors: counts.errors,
            warnings: counts.warnings,
            failure: failure,
            checked: checked,
            findings: findings,
            text: text
        });
    }

    Process {
        id: doctor

        // A result needs the exit code and both streams, in any order.
        property var code: null
        property string out: ""
        property string err: ""
        property int streams: 0

        function start() {
            code = null;
            streams = 0;
            running = true;
        }

        function finish() {
            if (code === null || streams < 2)
                return;
            const report = code === 0 ? Model.parse(out) : null;
            if (!report) {
                root.failure = "kaizen doctor: " + (err.trim() || (code === 0 ? "no report" : "exited with " + code));
                return;
            }
            root.findings = report.findings;
            root.text = report.text;
            root.checked = Date.now();
            root.failure = "";
        }

        command: ["kaizen", "doctor", "--json"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                doctor.out = text;
                doctor.streams++;
                doctor.finish();
            }
        }
        stderr: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                doctor.err = text;
                doctor.streams++;
                doctor.finish();
            }
        }
        onExited: function (exitCode) {
            doctor.code = exitCode;
            doctor.finish();
        }
    }

    Timer {
        interval: 60 * 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
