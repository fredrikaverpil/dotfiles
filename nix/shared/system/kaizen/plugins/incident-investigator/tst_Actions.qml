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
            arg: ""
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

    function item(fields) {
        return Object.assign({
            id: "a",
            status: "done",
            tag: "",
            sessionId: "",
            claudeConfigDir: "",
            messages: []
        }, fields);
    }

    function state(fields) {
        return Object.assign({
            current: null,
            picked: [],
            deletable: 0,
            clearable: 0,
            clearLabel: "Clear all",
            tags: [],
            model: Format.models[0],
            effort: "high",
            tagFilter: "",
            projectFilter: [],
            projects: []
        }, fields);
    }

    function test_itemRows_data() {
        const prodTag = row({
            key: "tag",
            text: "Tag",
            glyph: Format.icons.tag,
            detail: "prod",
            hasChildren: true,
            children: [radio("tag.prod", "prod", true, "tag", ""), radio("tag.dev", "dev", false, "tag", "dev")]
        });
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
        const remove = row({
            key: "delete",
            text: "Delete",
            glyph: Format.icons.trash,
            keys: ["Backspace"],
            action: "delete"
        });
        return [
            {
                tag: "draft",
                item: item({
                    status: "draft",
                    tag: "prod"
                }),
                tags: tags,
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
                    }), prodTag]
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
                want: [row({
                        key: "stop",
                        text: "Stop",
                        glyph: Format.icons.stop,
                        action: "stop"
                    }), terminal, prodTag]
            },
            {
                tag: "done",
                item: item({
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
                }),
                tags: tags,
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
                    }), prodTag, remove]
            },
            {
                tag: "failed without answer or tags",
                item: item({
                    status: "failed"
                }),
                tags: [],
                want: [rerun, remove]
            }
        ];
    }

    function test_itemRows(data) {
        const got = Actions.itemRows(data.item, data.tags);

        compare(got, data.want);
    }

    function test_pickedRows_data() {
        const combine = row({
            key: "combine",
            text: "Combine",
            glyph: Format.icons.plus,
            detail: "2 investigations",
            action: "combine"
        });
        const unpick = row({
            key: "unpick",
            text: "Unpick",
            glyph: Format.icons.close,
            keys: ["Esc"],
            action: "unpick"
        });
        return [
            {
                tag: "deletable",
                deletable: 2,
                want: [combine, unpick, row({
                        key: "delete",
                        text: "Delete 2",
                        glyph: Format.icons.trash,
                        keys: ["Backspace"],
                        action: "delete"
                    })]
            },
            {
                tag: "all running",
                deletable: 0,
                want: [combine, unpick]
            }
        ];
    }

    function test_pickedRows(data) {
        const got = Actions.pickedRows(state({
            picked: [item({}), item({
                    id: "b"
                })],
            deletable: data.deletable
        }));

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
                tag: "no tags or projects",
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
                    clearLabel: "Clear listed",
                    tags: tags,
                    tagFilter: "dev",
                    projectFilter: ["p-dev"],
                    projects: ["p-dev", "p-prod"]
                }),
                want: [row({
                        key: "new",
                        text: "New investigation",
                        glyph: Format.icons.plus,
                        detail: "tag dev",
                        action: "new"
                    }), row({
                        key: "clear",
                        text: "Clear listed",
                        glyph: Format.icons.trash,
                        action: "clear"
                    }), model, effort, row({
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
                                children: [radio("filter.tag.", "All", false, "filterTag", ""), radio("filter.tag.prod", "prod", false, "filterTag", "prod"), radio("filter.tag.dev", "dev", true, "filterTag", "dev")]
                            }), row({
                                key: "filter.project",
                                text: "Project",
                                glyph: Format.icons.filter,
                                detail: "p-dev",
                                hasChildren: true,
                                children: [radio("filter.project.", "All projects", false, "filterProject", ""), row({
                                        key: "filter.project.p-dev",
                                        text: "p-dev",
                                        glyph: Format.icons.checkOn,
                                        action: "filterProject",
                                        arg: "p-dev"
                                    }), row({
                                        key: "filter.project.p-prod",
                                        text: "p-prod",
                                        glyph: Format.icons.check,
                                        action: "filterProject",
                                        arg: "p-prod"
                                    })]
                            })]
                    })]
            }
        ];
    }

    function test_windowRows(data) {
        const got = Actions.windowRows(data.state);

        compare(got, data.want);
    }

    function test_actions_data() {
        const draft = item({
            status: "draft"
        });
        const separator = {
            isSeparator: true,
            enabled: true
        };
        return [
            {
                tag: "nothing selected",
                state: state({}),
                want: Actions.windowRows(state({}))
            },
            {
                tag: "focused first",
                state: state({
                    current: draft
                }),
                want: Actions.itemRows(draft, []).concat([separator], Actions.windowRows(state({})))
            },
            {
                tag: "picked set over focused",
                state: state({
                    current: draft,
                    picked: [draft, item({})]
                }),
                want: Actions.pickedRows(state({
                    picked: [draft, item({})]
                })).concat([separator], Actions.windowRows(state({})))
            }
        ];
    }

    function test_actions(data) {
        const got = Actions.actions(data.state);

        compare(got, data.want);
    }
}
