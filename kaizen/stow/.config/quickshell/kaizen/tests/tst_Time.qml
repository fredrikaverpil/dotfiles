import QtQuick
import QtTest
import "../Ui/Time.js" as Time

TestCase {
    name: "Time"

    function test_stamp_data() {
        const now = new Date(2026, 10, 12, 14, 2);
        return [
            {
                tag: "today",
                at: new Date(2026, 10, 12, 9, 5),
                now: now,
                want: "09:05"
            },
            {
                tag: "yesterday",
                at: new Date(2026, 10, 11, 23, 59),
                now: now,
                want: "Wed 23:59"
            },
            {
                tag: "a week ago",
                at: new Date(2026, 10, 5, 14, 2),
                now: now,
                want: "Thu 14:02"
            },
        ];
    }

    function test_stamp(data) {
        compare(Time.stamp(data.at, data.now), data.want);
    }
}
