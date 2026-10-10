import QtQuick
import QtTest
import "../modules/services/log/LogModel.js" as Log

TestCase {
    name: "LogModel"

    // 08:41:23 local time, whatever the test machine's zone.
    readonly property real morning: new Date(2026, 9, 10, 8, 41, 23).getTime()

    function test_parse_data() {
        return [
            {
                tag: "warning",
                line: '{"time":1791619310034,"unit":"kaizen-shell","level":"WARN","message":"WARN scene: binding loop"}',
                want: {
                    time: 1791619310034,
                    unit: "kaizen-shell",
                    level: "WARN",
                    message: "WARN scene: binding loop"
                }
            },
            {
                tag: "extra field",
                line: '{"time":1,"unit":"kaizen-dcal","level":"ERROR","message":"error: x","cursor":"s=1"}',
                want: {
                    time: 1,
                    unit: "kaizen-dcal",
                    level: "ERROR",
                    message: "error: x"
                }
            },
            {
                tag: "empty",
                line: "",
                want: null
            },
            {
                tag: "text output",
                line: "Oct 10 08:41:23 kaizen-shell: WARN scene: x",
                want: null
            },
            {
                tag: "journalctl error",
                line: "journalctl: unrecognized option '--json'",
                want: null
            },
            {
                tag: "info level",
                line: '{"time":1,"unit":"kaizen-shell","level":"INFO","message":"x"}',
                want: null
            },
            {
                tag: "missing message",
                line: '{"time":1,"unit":"kaizen-shell","level":"WARN"}',
                want: null
            },
            {
                tag: "null",
                line: "null",
                want: null
            }
        ];
    }

    function test_parse(data) {
        // Act
        const got = Log.parse(data.line);

        // Assert
        compare(got, data.want);
    }

    function test_append_data() {
        return [
            {
                tag: "under limit",
                entries: [1, 2],
                more: [3],
                limit: 5,
                want: [1, 2, 3]
            },
            {
                tag: "drops oldest",
                entries: [1, 2, 3],
                more: [4, 5],
                limit: 3,
                want: [3, 4, 5]
            },
            {
                tag: "burst over limit",
                entries: [],
                more: [1, 2, 3, 4],
                limit: 2,
                want: [3, 4]
            }
        ];
    }

    function test_append(data) {
        // Act
        const got = Log.append(data.entries, data.more, data.limit);

        // Assert
        compare(got, data.want);
    }

    function test_role_data() {
        return [
            {
                tag: "warning",
                level: "WARN",
                want: "wood"
            },
            {
                tag: "error",
                level: "ERROR",
                want: "rose"
            },
            {
                tag: "fatal",
                level: "FATAL",
                want: "rose"
            }
        ];
    }

    function test_role(data) {
        // Act
        const got = Log.role(data.level);

        // Assert
        compare(got, data.want);
    }

    function test_line() {
        // Arrange
        const entry = {
            time: morning,
            unit: "kaizen-hello-tray",
            level: "ERROR",
            message: "systray error: failed to register"
        };

        // Act
        const got = Log.line(entry);

        // Assert
        verify(got === "08:41:23 kaizen-hello-tray: systray error: failed to register", got);
    }
}
