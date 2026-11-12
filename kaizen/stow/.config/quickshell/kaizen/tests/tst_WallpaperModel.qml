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
}
