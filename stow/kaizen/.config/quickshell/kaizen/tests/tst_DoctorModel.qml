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

    function test_html_data() {
        const palette = {
            rose: "#ff0000",
            wood: "#00ff00"
        };
        return [
            {
                tag: "report",
                text: "1 error, 1 warning\n\nERROR niri  check\n  niri validate:\n  <foo> & bar\nWARN  kaizen-shell  08:41:23\n  WARN qml: x",
                palette: palette,
                want: '<div style="white-space: pre-wrap">1 error, 1 warning<br><br>' + '<span style="color: #ff0000">ERROR</span> niri  check<br>' + "  niri validate:<br>  &lt;foo&gt; &amp; bar<br>" + '<span style="color: #00ff00">WARN</span>  kaizen-shell  08:41:23<br>' + "  WARN qml: x</div>"
            },
            {
                tag: "no findings",
                text: "No errors or warnings",
                palette: palette,
                want: '<div style="white-space: pre-wrap">No errors or warnings</div>'
            }
        ];
    }

    function test_html(data) {
        // Act
        const got = Doctor.html(data.text, data.palette);

        // Assert
        verify(got === data.want, got);
    }

    function test_clock() {
        // Act
        const got = Doctor.clock(morning);

        // Assert
        verify(got === "08:41:23", got);
    }
}
