import QtQuick
import QtTest
import "Actions.js" as Actions
import "Format.js" as Format

TestCase {
    name: "Actions"

    readonly property var tags: [
        {
            name: "prod",
            color: "rose"
        },
        {
            name: "dev",
            color: "water"
        }
    ]

    function row(fields) {
        return Object.assign({
            key: "",
            text: "",
            glyph: "",
            detail: "",
            keys: [],
            enabled: true,
            isSeparator: false,
            hasChildren: false,
            children: [],
            action: "",
            arg: "",
            ids: []
        }, fields);
    }

    function radio(key, text, on, action, arg) {
        return row({
            key: key,
            text: text,
            glyph: on ? Format.icons.radioOn : Format.icons.radio,
            action: action,
            arg: arg
        });
    }

    function check(key, text, on, action, arg) {
        return row({
            key: key,
            text: text,
            glyph: on ? Format.icons.checkOn : Format.icons.check,
            action: action,
            arg: arg
        });
    }

    function counted(row, count) {
        return Object.assign({}, row, {
            detail: count
        });
    }

    // The rows with ids set, their submenus' too.
    function about(ids, rows) {
        return rows.map(each => Object.assign({}, each, {
                ids: ids,
                children: about(ids, each.children)
            }));
    }

    function tagMenu(tag, ids) {
        return row({
            key: "tag",
            text: "Tag",
            glyph: Format.icons.tag,
            detail: tag,
            hasChildren: true,
            children: [radio("tag.prod", "prod", tag === "prod", "tag", tag === "prod" ? "" : "prod"), radio("tag.dev", "dev", tag === "dev", "tag", tag === "dev" ? "" : "dev")]
        });
    }

    function item(fields) {
        return Object.assign({
            id: "a",
            title: "",
            traceId: "",
            startedAt: 0,
            status: "done",
            tag: "",
            projects: [],
            sessionId: "",
            claudeConfigDir: "",
            messages: []
        }, fields);
    }

    function state(fields) {
        return Object.assign({
            listed: [],
            picked: [],
            clearable: 0,
            clearLabel: "Clear all",
            tags: [],
            tagCounts: {},
            model: Format.models[0],
            effort: "high",
            tagFilter: "",
            projectFilter: [],
            projects: []
        }, fields);
    }

    readonly property var done: item({
        status: "done",
        tag: "prod",
        sessionId: "s",
        claudeConfigDir: "/c",
        messages: [
            {
                kind: "assistant",
                text: "first"
            },
            {
                kind: "user",
                text: "why"
            },
            {
                kind: "assistant",
                text: "last"
            }
        ]
    })

    function test_itemRows_data() {
        const terminal = row({
            key: "terminal",
            text: "Terminal",
            glyph: Format.icons.terminal,
            action: "terminal"
        });
        const rerun = row({
            key: "rerun",
            text: "Re-run",
            glyph: Format.icons.refresh,
            action: "rerun"
        });
        return [
            {
                tag: "draft",
                item: item({
                    status: "draft",
                    tag: "prod"
                }),
                tags: tags,
                selection: "",
                want: [row({
                        key: "run",
                        text: "Run",
                        glyph: Format.icons.play,
                        action: "run"
                    }), row({
                        key: "discard",
                        text: "Discard",
                        glyph: Format.icons.trash,
                        action: "discard"
                    }), tagMenu("prod")]
            },
            {
                tag: "running",
                item: item({
                    status: "running",
                    tag: "prod",
                    sessionId: "s",
                    claudeConfigDir: "/c",
                    messages: [
                        {
                            kind: "assistant",
                            text: "so far"
                        }
                    ]
                }),
                tags: tags,
                selection: "",
                want: [row({
                        key: "stop",
                        text: "Stop",
                        glyph: Format.icons.stop,
                        action: "stop"
                    }), terminal, tagMenu("prod")]
            },
            {
                tag: "done with a selection",
                item: done,
                tags: tags,
                selection: "fir",
                want: [rerun, row({
                        key: "followUp",
                        text: "Follow up",
                        glyph: Format.icons.reply,
                        action: "followUp"
                    }), terminal, row({
                        key: "copy",
                        text: "Copy answer",
                        glyph: Format.icons.copy,
                        action: "copy",
                        arg: "last"
                    }), row({
                        key: "copySelection",
                        text: "Copy selection",
                        glyph: Format.icons.copy,
                        action: "copy",
                        arg: "fir"
                    }), tagMenu("prod")]
            },
            {
                tag: "failed without answer or tags",
                item: item({
                    status: "failed"
                }),
                tags: [],
                selection: "",
                want: [rerun]
            }
        ];
    }

    function test_itemRows(data) {
        const got = Actions.itemRows(data.item, data.tags, data.selection);

        compare(got, data.want);
    }

    function test_rowRows_data() {
        const failed = item({
            status: "failed"
        });
        const draft = item({
            status: "draft"
        });
        const open = status => row({
                key: "open",
                text: "Open",
                glyph: Format.icons[status],
                keys: ["Enter"],
                action: "open"
            });
        const pick = row({
            key: "pick",
            text: "Pick",
            glyph: Format.icons.check,
            keys: ["Space"],
            action: "pick"
        });
        const combine = row({
            key: "combine",
            text: "Combine",
            glyph: Format.icons.plus,
            enabled: false,
            action: "combine"
        });
        const picked = state({
            picked: [failed, item({
                    id: "b"
                })]
        });
        return [
            {
                tag: "deletable",
                state: state({}),
                item: failed,
                want: about(["a"], [open("failed"), row({
                        key: "rerun",
                        text: "Re-run",
                        glyph: Format.icons.refresh,
                        action: "rerun"
                    }), pick, combine, row({
                        key: "delete",
                        text: "Delete",
                        glyph: Format.icons.trash,
                        keys: ["Backspace"],
                        action: "delete"
                    })])
            },
            {
                tag: "draft",
                state: state({}),
                item: draft,
                want: about(["a"], [open("draft")].concat(Actions.itemRows(draft, [], ""), [pick, combine]))
            },
            {
                tag: "picked set",
                state: picked,
                item: failed,
                want: Actions.pickedRows(picked, true)
            }
        ];
    }

    function test_rowRows(data) {
        const got = Actions.rowRows(data.state, data.item);

        compare(got, data.want);
    }

    function test_contextRows_data() {
        const failed = item({
            status: "failed"
        });
        const other = item({
            id: "b"
        });
        const rows = keys => about(["a"], [row({
                    key: "open",
                    text: "Open",
                    glyph: Format.icons.failed,
                    keys: ["Enter"],
                    action: "open"
                }), row({
                    key: "rerun",
                    text: "Re-run",
                    glyph: Format.icons.refresh,
                    action: "rerun"
                }), row({
                    key: "pick",
                    text: "Pick",
                    glyph: Format.icons.check,
                    keys: ["Space"],
                    action: "pick"
                }), row({
                    key: "combine",
                    text: "Combine",
                    glyph: Format.icons.plus,
                    enabled: false,
                    action: "combine"
                }), row({
                    key: "delete",
                    text: "Delete",
                    glyph: Format.icons.trash,
                    keys: keys,
                    action: "delete"
                })]);
        const pickedWith = state({
            picked: [failed, other]
        });
        return [
            {
                tag: "nothing picked",
                state: state({}),
                item: failed,
                want: rows(["Backspace"])
            },
            {
                tag: "unpicked row while others are picked",
                state: state({
                    picked: [other, item({
                            id: "c"
                        })]
                }),
                item: failed,
                want: rows([])
            },
            {
                tag: "picked row",
                state: pickedWith,
                item: failed,
                want: Actions.pickedRows(pickedWith, true)
            }
        ];
    }

    function test_contextRows(data) {
        const got = Actions.contextRows(data.state, data.item);

        compare(got, data.want);
    }

    function test_pickedRows_data() {
        return [
            {
                tag: "keyed, a shared tag",
                state: state({
                    tags: tags,
                    picked: [item({
                            tag: "dev"
                        }), item({
                            id: "b",
                            tag: "dev"
                        })]
                }),
                keyed: true,
                want: about(["a", "b"], [row({
                        key: "combine",
                        text: "Combine",
                        glyph: Format.icons.plus,
                        detail: "2 investigations",
                        action: "combine"
                    }), tagMenu("dev"), row({
                        key: "unpick",
                        text: "Unpick",
                        glyph: Format.icons.close,
                        keys: ["Esc"],
                        action: "unpick"
                    }), row({
                        key: "delete",
                        text: "Delete 2",
                        glyph: Format.icons.trash,
                        keys: ["Backspace"],
                        action: "delete"
                    })])
            },
            {
                tag: "one running, tags differ",
                state: state({
                    tags: tags,
                    picked: [item({
                            status: "running",
                            tag: "dev"
                        })]
                }),
                keyed: false,
                want: about(["a"], [row({
                        key: "combine",
                        text: "Combine",
                        glyph: Format.icons.plus,
                        detail: "1 investigation",
                        enabled: false,
                        action: "combine"
                    }), tagMenu("dev"), row({
                        key: "unpick",
                        text: "Unpick",
                        glyph: Format.icons.close,
                        action: "unpick"
                    })])
            },
            {
                tag: "no shared tag",
                state: state({
                    tags: tags,
                    picked: [item({
                            status: "running",
                            tag: "dev"
                        }), item({
                            id: "b",
                            status: "running"
                        })]
                }),
                keyed: false,
                want: about(["a", "b"], [row({
                        key: "combine",
                        text: "Combine",
                        glyph: Format.icons.plus,
                        detail: "2 investigations",
                        action: "combine"
                    }), tagMenu(""), row({
                        key: "unpick",
                        text: "Unpick",
                        glyph: Format.icons.close,
                        action: "unpick"
                    })])
            }
        ];
    }

    function test_pickedRows(data) {
        const got = Actions.pickedRows(data.state, data.keyed);

        compare(got, data.want);
    }

    function test_filterRows_data() {
        return [
            {
                tag: "no tags or projects",
                state: state({}),
                want: []
            },
            {
                tag: "tags counted, all filtered",
                state: state({
                    tags: tags,
                    tagCounts: {
                        "": 3,
                        prod: 2
                    }
                }),
                want: [row({
                        key: "filter.tag",
                        text: "Tag",
                        glyph: Format.icons.tag,
                        hasChildren: true,
                        children: [counted(radio("filter.tag.", "All", true, "filterTag", ""), "3"), counted(radio("filter.tag.prod", "prod", false, "filterTag", "prod"), "2"), counted(radio("filter.tag.dev", "dev", false, "filterTag", "dev"), "0")]
                    })]
            },
            {
                tag: "projects only",
                state: state({
                    projectFilter: ["p-dev"],
                    projects: ["p-dev", "p-prod"]
                }),
                want: [row({
                        key: "filter.project",
                        text: "Project",
                        glyph: Format.icons.filter,
                        detail: "p-dev",
                        hasChildren: true,
                        children: [radio("filter.project.", "All projects", false, "filterProject", ""), check("filter.project.p-dev", "p-dev", true, "filterProject", "p-dev"), check("filter.project.p-prod", "p-prod", false, "filterProject", "p-prod")]
                    })]
            }
        ];
    }

    function test_filterRows(data) {
        const got = Actions.filterRows(data.state);

        compare(got, data.want);
    }

    function test_listRows_data() {
        const search = row({
            key: "search",
            text: "Search list",
            glyph: Format.icons.filter,
            action: "search"
        });
        const first = item({
            title: "Errors spike",
            projects: ["p-dev"]
        });
        const second = item({
            id: "b",
            title: "Latency",
            status: "running"
        });
        return [
            {
                tag: "empty",
                state: state({}),
                want: [search]
            },
            {
                tag: "filtered and picked",
                state: state({
                    listed: [first, second],
                    picked: [second],
                    tags: tags,
                    tagCounts: {
                        "": 2,
                        dev: 1
                    },
                    tagFilter: "dev",
                    projectFilter: ["p-dev"],
                    projects: ["p-dev", "p-prod"]
                }),
                want: [search, row({
                        key: "filter",
                        text: "Filter",
                        glyph: Format.icons.filter,
                        detail: "dev, p-dev",
                        hasChildren: true,
                        children: [row({
                                key: "filter.tag",
                                text: "Tag",
                                glyph: Format.icons.tag,
                                detail: "dev",
                                hasChildren: true,
                                children: [counted(radio("filter.tag.", "All", false, "filterTag", ""), "2"), counted(radio("filter.tag.prod", "prod", false, "filterTag", "prod"), "0"), counted(radio("filter.tag.dev", "dev", true, "filterTag", "dev"), "1")]
                            }), row({
                                key: "filter.project",
                                text: "Project",
                                glyph: Format.icons.filter,
                                detail: "p-dev",
                                hasChildren: true,
                                children: [radio("filter.project.", "All projects", false, "filterProject", ""), check("filter.project.p-dev", "p-dev", true, "filterProject", "p-dev"), check("filter.project.p-prod", "p-prod", false, "filterProject", "p-prod")]
                            })]
                    }), row({
                        key: "pickAll",
                        text: "Pick all listed",
                        glyph: Format.icons.checkOn,
                        action: "pickAll"
                    }), row({
                        key: "unpick",
                        text: "Unpick",
                        glyph: Format.icons.close,
                        keys: ["Esc"],
                        action: "unpick"
                    }), row({
                        key: "goto",
                        text: "Go to",
                        glyph: Format.icons.arrow,
                        hasChildren: true,
                        children: [row({
                                key: "goto.a",
                                text: "Errors spike",
                                glyph: Format.icons.done,
                                detail: "p-dev",
                                action: "select",
                                arg: "a"
                            }), row({
                                key: "goto.b",
                                text: "Latency",
                                glyph: Format.icons.running,
                                action: "select",
                                arg: "b"
                            })]
                    })]
            }
        ];
    }

    function test_listRows(data) {
        const got = Actions.listRows(data.state);

        compare(got, data.want);
    }

    function test_draftRows_data() {
        const run = row({
            key: "run",
            text: "Run",
            glyph: Format.icons.play,
            keys: ["Ctrl", "Enter"],
            action: "run"
        });
        const discard = row({
            key: "discard",
            text: "Discard",
            glyph: Format.icons.trash,
            action: "discard"
        });
        const add = row({
            key: "projects.add",
            text: "Add a project…",
            glyph: Format.icons.plus,
            action: "addProject"
        });
        const fields = [row({
                key: "trace",
                text: "Trace id",
                glyph: Format.icons.draft,
                action: "focusTrace"
            }), row({
                key: "notes",
                text: "Notes",
                glyph: Format.icons.draft,
                action: "focusNotes"
            })];
        return [
            {
                tag: "no tags or projects",
                state: state({}),
                draft: {
                    id: "a",
                    tag: "",
                    projects: [],
                    choices: []
                },
                want: about(["a"], [run, discard, row({
                        key: "projects",
                        text: "Projects",
                        glyph: Format.icons.filter,
                        hasChildren: true,
                        children: [add]
                    })].concat(fields))
            },
            {
                tag: "tagged with a project",
                state: state({
                    tags: tags
                }),
                draft: {
                    id: "a",
                    tag: "prod",
                    projects: ["p-prod"],
                    choices: ["p-dev", "p-prod"]
                },
                want: about(["a"], [run, discard, row({
                        key: "projects",
                        text: "Projects",
                        glyph: Format.icons.filter,
                        detail: "p-prod",
                        hasChildren: true,
                        children: [check("projects.p-dev", "p-dev", false, "project", "p-dev"), check("projects.p-prod", "p-prod", true, "project", "p-prod"), add]
                    }), tagMenu("prod")].concat(fields))
            }
        ];
    }

    function test_draftRows(data) {
        const got = Actions.draftRows(data.state, data.draft);

        compare(got, data.want);
    }

    function test_conversationRows_data() {
        const running = item({
            status: "running"
        });
        return [
            {
                tag: "done",
                item: done,
                want: about(["a"], Actions.itemRows(done, tags, "fir").concat([row({
                        key: "delete",
                        text: "Delete",
                        glyph: Format.icons.trash,
                        action: "delete"
                    })]))
            },
            {
                tag: "running",
                item: running,
                want: about(["a"], Actions.itemRows(running, tags, "fir"))
            }
        ];
    }

    function test_conversationRows(data) {
        const got = Actions.conversationRows(state({
            tags: tags
        }), data.item, "fir");

        compare(got, data.want);
    }

    function test_windowRows_data() {
        const model = row({
            key: "model",
            text: "Model",
            glyph: Format.icons.model,
            detail: Format.models[0],
            hasChildren: true,
            children: Format.models.map(name => radio("model." + name, name, name === Format.models[0], "model", name))
        });
        const effort = row({
            key: "effort",
            text: "Effort",
            glyph: Format.icons.effort,
            detail: "high",
            hasChildren: true,
            children: Format.efforts.map(name => radio("effort." + name, name, name === "high", "effort", name))
        });
        return [
            {
                tag: "nothing to clear",
                state: state({}),
                want: [row({
                        key: "new",
                        text: "New investigation",
                        glyph: Format.icons.plus,
                        action: "new"
                    }), model, effort]
            },
            {
                tag: "filtered",
                state: state({
                    clearable: 3,
                    clearLabel: "Clear dev",
                    tagFilter: "dev"
                }),
                want: [row({
                        key: "new",
                        text: "New investigation",
                        glyph: Format.icons.plus,
                        detail: "tag dev",
                        action: "new"
                    }), row({
                        key: "clear",
                        text: "Clear dev",
                        glyph: Format.icons.trash,
                        action: "clear"
                    }), model, effort]
            }
        ];
    }

    function test_windowRows(data) {
        const got = Actions.windowRows(data.state);

        compare(got, data.want);
    }
}
