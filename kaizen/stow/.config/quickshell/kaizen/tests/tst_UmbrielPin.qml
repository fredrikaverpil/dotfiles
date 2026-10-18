import QtQuick
import QtTest
import "../Ui/compositors/UmbrielPin.js" as Pin

TestCase {
    name: "UmbrielPin"

    function test_window_id_data() {
        return [
            {
                tag: "window appears",
                raw: '{"event":"windows","data":[{"id":"a1","app_id":"other"},{"id":"c4","app_id":"cam"}]}',
                id: 0,
                want: "c4"
            },
            {
                tag: "window gone",
                raw: '{"event":"windows","data":[{"id":"a1","app_id":"other"}]}',
                id: "c4",
                want: 0
            },
            {
                tag: "other event",
                raw: '{"event":"workspaces","data":[]}',
                id: "c4",
                want: "c4"
            },
            {
                tag: "invalid",
                raw: "invalid",
                id: "c4",
                want: "c4"
            }
        ];
    }

    function test_window_id(data) {
        verify(Pin.windowId(data.raw, "cam", data.id) === data.want);
    }
}
