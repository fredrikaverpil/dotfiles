import QtQuick
import QtTest
import "../Ui/compositors/UmbrielPin.js" as Pin

TestCase {
    name: "UmbrielPin"

    function test_window_id_data() {
        return [
            {
                tag: "window present",
                windows: [
                    {
                        id: "a1",
                        app_id: "other"
                    },
                    {
                        id: "c4",
                        app_id: "cam"
                    }
                ],
                want: "c4"
            },
            {
                tag: "window absent",
                windows: [
                    {
                        id: "a1",
                        app_id: "other"
                    }
                ],
                want: 0
            },
            {
                tag: "no snapshot",
                windows: null,
                want: 0
            }
        ];
    }

    function test_window_id(data) {
        verify(Pin.windowId(data.windows, "cam") === data.want);
    }
}
