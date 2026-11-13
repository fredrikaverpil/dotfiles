import QtQuick
import QtTest
import "../modules/background/WallpaperModel.js" as Model

TestCase {
    name: "WallpaperModel"

    readonly property string root: "/w"

    function test_dirOf_data() {
        return [
            {
                tag: "root",
                path: "/w/a.png",
                want: ""
            },
            {
                tag: "folder",
                path: "/w/Ghibli/a.png",
                want: "Ghibli"
            },
            {
                tag: "nested",
                path: "/w/Ghibli/Totoro/a.png",
                want: "Ghibli/Totoro"
            }
        ];
    }

    function test_dirOf(data) {
        verify(Model.dirOf(data.path, root) === data.want);
    }

    function test_sorted_data() {
        return [
            {
                tag: "empty",
                paths: [],
                want: []
            },
            {
                tag: "root first, then folders, each by path",
                paths: ["/w/b/2.png", "/w/z.png", "/w/a/1.png", "/w/b/1.png", "/w/c.png"],
                want: ["/w/c.png", "/w/z.png", "/w/a/1.png", "/w/b/1.png", "/w/b/2.png"]
            }
        ];
    }

    function test_sorted(data) {
        compare(Model.sorted(data.paths, root), data.want);
    }

    function test_layout_data() {
        return [
            {
                tag: "empty",
                paths: [],
                columns: 2,
                want: {
                    rows: [],
                    rowOfIndex: []
                }
            },
            {
                tag: "root wraps at columns",
                paths: ["/w/1.png", "/w/2.png", "/w/3.png"],
                columns: 2,
                want: {
                    rows: [
                        {
                            header: true,
                            label: "Wallpapers"
                        },
                        {
                            header: false,
                            start: 0,
                            count: 2
                        },
                        {
                            header: false,
                            start: 2,
                            count: 1
                        }
                    ],
                    rowOfIndex: [1, 1, 2]
                }
            },
            {
                tag: "a header per folder",
                paths: ["/w/1.png", "/w/a/1.png", "/w/a/2.png"],
                columns: 6,
                want: {
                    rows: [
                        {
                            header: true,
                            label: "Wallpapers"
                        },
                        {
                            header: false,
                            start: 0,
                            count: 1
                        },
                        {
                            header: true,
                            label: "a"
                        },
                        {
                            header: false,
                            start: 1,
                            count: 2
                        }
                    ],
                    rowOfIndex: [1, 3, 3]
                }
            }
        ];
    }

    function test_layout(data) {
        compare(Model.layout(data.paths, root, data.columns), data.want);
    }

    // Rows: 0 "Wallpapers", 1 [0, 1], 2 [2], 3 "a", 4 [3, 4].
    readonly property var grid: Model.layout(["/w/1.png", "/w/2.png", "/w/3.png", "/w/a/1.png", "/w/a/2.png"], root, 2)

    function test_step_data() {
        return [
            {
                tag: "down to a shorter row",
                index: 1,
                dir: 1,
                want: 2
            },
            {
                tag: "down past a header",
                index: 2,
                dir: 1,
                want: 3
            },
            {
                tag: "up past a header",
                index: 3,
                dir: -1,
                want: 2
            },
            {
                tag: "up to the row's last",
                index: 4,
                dir: -1,
                want: 2
            },
            {
                tag: "up from the first row",
                index: 0,
                dir: -1,
                want: -1
            },
            {
                tag: "down from the last row",
                index: 4,
                dir: 1,
                want: -1
            },
            {
                tag: "no such index",
                index: 9,
                dir: 1,
                want: -1
            }
        ];
    }

    function test_step(data) {
        const got = Model.step(grid.rows, grid.rowOfIndex, data.index, data.dir);

        compare(got, data.want);
    }

    function test_reveal_data() {
        return [
            {
                tag: "a folder's first row, with its label",
                index: 0,
                want: [1, 0]
            },
            {
                tag: "a later row",
                index: 2,
                want: [2]
            },
            {
                tag: "another folder's first row",
                index: 4,
                want: [4, 3]
            },
            {
                tag: "no such index",
                index: 9,
                want: []
            }
        ];
    }

    function test_reveal(data) {
        const got = Model.reveal(grid.rows, grid.rowOfIndex, data.index);

        compare(got, data.want);
    }
}
