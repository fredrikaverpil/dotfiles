import QtQuick
import QtTest
import "../Ui/InfoTableModel.js" as Table

TestCase {
    name: "InfoTableModel"

    // One unit per character.
    function measure(text) {
        return text.length;
    }

    function test_cells_place_entries_side_by_side() {
        const entries = [
            {
                label: "IP",
                value: "10.0.0.2"
            },
            {
                label: "Ping",
                value: "9 ms"
            },
            {
                label: "Rate",
                value: "1 kB/s"
            }
        ];
        compare(Table.cells(entries, 2), [
            {
                text: "IP",
                label: true,
                column: 0
            },
            {
                text: "10.0.0.2",
                label: false,
                column: 1
            },
            {
                text: "Ping",
                label: true,
                column: 2
            },
            {
                text: "9 ms",
                label: false,
                column: 3
            },
            {
                text: "Rate",
                label: true,
                column: 0
            },
            {
                text: "1 kB/s",
                label: false,
                column: 1
            }
        ]);
    }

    function test_column_widths_data() {
        return [
            {
                tag: "widest cell per column across tables",
                entrySets: [[
                        {
                            label: "Ping",
                            value: "9 ms"
                        },
                        {
                            label: "Rate",
                            value: "1 kB/s"
                        }
                    ], [
                        {
                            label: "Packet loss",
                            value: "0 %"
                        },
                        {
                            label: "Rate",
                            value: "120 B/s"
                        }
                    ]],
                perLine: 2,
                want: [11, 4, 4, 7]
            },
            {
                tag: "one per line",
                entrySets: [[
                        {
                            label: "Rate",
                            value: "0.0 W"
                        },
                        {
                            label: "Cycles",
                            value: "12"
                        }
                    ]],
                perLine: 1,
                want: [6, 5]
            },
            {
                tag: "no tables",
                entrySets: [],
                perLine: 2,
                want: [0, 0, 0, 0]
            }
        ];
    }

    function test_column_widths(data) {
        compare(Table.columnWidths(data.entrySets, data.perLine, measure), data.want);
    }
}
