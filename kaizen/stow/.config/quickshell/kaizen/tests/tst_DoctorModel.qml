import QtQuick
import QtTest
import "../modules/services/doctor/DoctorModel.js" as Doctor

TestCase {
    name: "DoctorModel"

    // 08:41:23 local time, whatever the test machine's zone.
    readonly property real morning: new Date(2026, 9, 10, 8, 41, 23).getTime()

    readonly property var warning: ({
            source: "log",
            level: "WARN",
            unit: "kaizen-shell",
            message: "WARN scene: binding loop",
            count: 2,
            first: 1791619310034,
            last: 1791619320034
        })

    readonly property var error: ({
            source: "check",
            level: "ERROR",
            unit: "niri",
            message: "niri validate:\nError: unexpected node",
            count: 1,
            first: 1791619330034,
            last: 1791619330034
        })

    function test_parse_data() {
        return [
            {
                tag: "report",
                output: JSON.stringify({
                    findings: [error, warning],
                    text: "1 error, 1 warning"
                }),
                want: {
                    findings: [error, warning],
                    text: "1 error, 1 warning"
                }
            },
            {
                tag: "empty report",
                output: '{"findings":[],"text":"No errors or warnings"}',
                want: {
                    findings: [],
                    text: "No errors or warnings"
                }
            },
            {
                tag: "extra field",
                output: '{"findings":[],"text":"x","version":1}',
                want: {
                    findings: [],
                    text: "x"
                }
            },
            {
                tag: "empty",
                output: "",
                want: null
            },
            {
                tag: "text output",
                output: "No errors or warnings",
                want: null
            },
            {
                tag: "missing text",
                output: '{"findings":[]}',
                want: null
            },
            {
                tag: "info level",
                output: JSON.stringify({
                    findings: [Object.assign({}, warning, {
                            level: "INFO"
                        })],
                    text: "x"
                }),
                want: null
            },
            {
                tag: "unknown source",
                output: JSON.stringify({
                    findings: [Object.assign({}, warning, {
                            source: "x"
                        })],
                    text: "x"
                }),
                want: null
            },
            {
                tag: "null",
                output: "null",
                want: null
            }
        ];
    }

    function test_parse(data) {
        // Act
        const got = Doctor.parse(data.output);

        // Assert
        compare(got, data.want);
    }

    function test_counts_data() {
        return [
            {
                tag: "none",
                findings: [],
                want: {
                    errors: 0,
                    warnings: 0
                }
            },
            {
                tag: "both",
                findings: [error, warning, warning],
                want: {
                    errors: 1,
                    warnings: 2
                }
            }
        ];
    }

    function test_counts(data) {
        // Act
        const got = Doctor.counts(data.findings);

        // Assert
        compare(got, data.want);
    }

    function test_summary_data() {
        return [
            {
                tag: "none",
                counts: {
                    errors: 0,
                    warnings: 0
                },
                want: ""
            },
            {
                tag: "one error",
                counts: {
                    errors: 1,
                    warnings: 0
                },
                want: "1 error"
            },
            {
                tag: "warnings",
                counts: {
                    errors: 0,
                    warnings: 2
                },
                want: "2 warnings"
            },
            {
                tag: "both",
                counts: {
                    errors: 2,
                    warnings: 1
                },
                want: "2 errors, 1 warning"
            }
        ];
    }

    function test_summary(data) {
        // Act
        const got = Doctor.summary(data.counts);

        // Assert
        compare(got, data.want);
    }

    function test_when_data() {
        return [
            {
                tag: "once",
                finding: Object.assign({}, warning, {
                    count: 1,
                    first: morning,
                    last: morning
                }),
                want: "08:41"
            },
            {
                tag: "repeated over a span",
                finding: Object.assign({}, warning, {
                    count: 3,
                    first: morning,
                    last: morning + 65000
                }),
                want: "×3 · 08:41–08:42"
            },
            {
                tag: "repeated in one minute",
                finding: Object.assign({}, warning, {
                    count: 4,
                    first: morning,
                    last: morning + 20000
                }),
                want: "×4 · 08:41"
            },
            {
                tag: "check",
                finding: error,
                want: ""
            }
        ];
    }

    function test_when(data) {
        // Act
        const got = Doctor.when(data.finding, new Date(morning));

        // Assert
        compare(got, data.want);
    }

    function test_copyText_data() {
        return [
            {
                tag: "no hint",
                finding: warning,
                want: "WARN scene: binding loop"
            },
            {
                tag: "hint",
                finding: Object.assign({}, error, {
                    hint: "niri validate"
                }),
                want: "niri validate:\nError: unexpected node\nniri validate"
            }
        ];
    }

    function test_copyText(data) {
        // Act
        const got = Doctor.copyText(data.finding);

        // Assert
        compare(got, data.want);
    }

    function test_key_data() {
        const finding = {
            source: "unit",
            id: "journal",
            level: "WARN",
            unit: "kaizen-shell.service",
            message: "binding loop",
            count: 1,
            first: 1,
            last: 1
        };
        return [
            {
                tag: "a later run's copy",
                a: finding,
                b: Object.assign({}, finding, {
                    level: "ERROR",
                    count: 3,
                    last: 9
                }),
                want: true
            },
            {
                tag: "another message",
                a: finding,
                b: Object.assign({}, finding, {
                    message: "other"
                }),
                want: false
            },
            {
                tag: "another unit",
                a: finding,
                b: Object.assign({}, finding, {
                    unit: "kaizen-dcal.service"
                }),
                want: false
            },
            {
                tag: "another check",
                a: finding,
                b: Object.assign({}, finding, {
                    id: "failed"
                }),
                want: false
            }
        ];
    }

    function test_key(data) {
        const got = Doctor.key(data.a) === Doctor.key(data.b);

        compare(got, data.want);
    }
}
