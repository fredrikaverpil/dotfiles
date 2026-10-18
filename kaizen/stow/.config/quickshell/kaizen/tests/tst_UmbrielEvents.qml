import QtQuick
import QtTest
import "../Ui/compositors/UmbrielEvents.js" as Events

TestCase {
    name: "UmbrielEvents"

    function test_snapshot_data() {
        return [
            {
                tag: "its family",
                event: {
                    event: "windows",
                    data: [
                        {
                            id: "a1"
                        }
                    ]
                },
                want: [
                    {
                        id: "a1"
                    }
                ]
            },
            {
                tag: "another family",
                event: {
                    event: "workspaces",
                    data: []
                },
                want: null
            },
            {
                tag: "no list",
                event: {
                    event: "windows",
                    data: null
                },
                want: null
            },
            {
                tag: "no event",
                event: null,
                want: null
            }
        ];
    }

    function test_snapshot(data) {
        compare(Events.snapshot(data.event, "windows"), data.want);
    }
}
