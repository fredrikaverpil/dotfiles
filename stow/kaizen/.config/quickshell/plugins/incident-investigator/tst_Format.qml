import QtQuick
import QtTest
import "Format.js" as Format

TestCase {
    name: "Format"

    function test_name_data() {
        return [
            {
                tag: "title",
                item: {
                    title: "Spanner abort",
                    traceId: "4f9d",
                    startedAt: 1
                },
                want: "Spanner abort"
            },
            {
                tag: "trace",
                item: {
                    title: "",
                    traceId: "4f9d",
                    startedAt: 1
                },
                want: "4f9d"
            },
            {
                tag: "started",
                item: {
                    title: "",
                    traceId: "",
                    startedAt: new Date(2026, 9, 1, 22, 28).getTime()
                },
                want: "2026-10-01 22:28"
            },
            {
                tag: "draft",
                item: {
                    traceId: "",
                    startedAt: 0
                },
                want: "New investigation"
            },
        ];
    }

    function test_name(data) {
        const got = Format.name(data.item);

        compare(got, data.want);
    }

    function test_matches_data() {
        const item = {
            title: "Spanner abort",
            traceId: "4f9d",
            projects: ["p-dev"],
            notes: "",
            error: "",
            alert: {
                app: "Slack",
                summary: "Error Log Alert",
                body: "Alert body"
            },
            messages: [
                {
                    kind: "user",
                    text: "Investigate"
                },
                {
                    kind: "tools",
                    commands: ["gcloud logging read x"]
                }
            ]
        };
        return [
            {
                tag: "empty",
                item: item,
                query: "",
                want: true
            },
            {
                tag: "trace",
                item: item,
                query: "4F9D",
                want: true
            },
            {
                tag: "alert",
                item: item,
                query: "alert body",
                want: true
            },
            {
                tag: "command",
                item: item,
                query: "LOGGING READ X",
                want: true
            },
            {
                tag: "none",
                item: item,
                query: "nope",
                want: false
            },
        ];
    }

    function test_matches(data) {
        const got = Format.matches(data.item, data.query);

        compare(got, data.want);
    }

    function test_blocks_split_headings_and_fences() {
        const markdown = "Intro\n\n## Likely root cause\n\nText\n```sh\n# a comment\nls\n```\nAfter\n~~~\nopen";

        const blocks = Format.blocks(markdown);

        compare(blocks, [
            {
                heading: false,
                code: false,
                text: "Intro\n"
            },
            {
                heading: true,
                code: false,
                text: "Likely root cause"
            },
            {
                heading: false,
                code: false,
                text: "\nText"
            },
            {
                heading: false,
                code: true,
                text: "# a comment\nls"
            },
            {
                heading: false,
                code: false,
                text: "After"
            },
            {
                heading: false,
                code: true,
                text: "open"
            },
        ]);
    }

    function test_inline_code_is_coloured_and_literal() {
        const markdown = "Trace `a*b_<i>&` in ``x`y`` and **bold** `🔥`";

        const html = Format.literals(markdown, "#6099C0");

        compare(html, 'Trace <span style="color:#6099C0">a&#42;b&#95;&#60;i&#62;&#38;</span>' + ' in <span style="color:#6099C0">x&#96;y</span> and **bold** <span style="color:#6099C0">🔥</span>');
    }

    function test_links_are_clickable_and_coloured() {
        const markdown = "Hit [the error](https://x.dev/a?b=1&c=2) twice";

        const html = Format.literals(markdown, "#6099C0");

        compare(html, 'Hit <a href="https://x.dev/a?b=1&amp;c=2"><span style="color:#6099C0">the error</span></a> twice');
    }

    function test_urls_are_coloured_and_not_linked() {
        const markdown = "See https://x.dev/a_b?c=1&d=2. And `https://y.dev`";

        const html = Format.literals(markdown, "#6099C0");

        compare(html, 'See <span style="color:#6099C0">https&#58;&#47;&#47;x&#46;dev&#47;a&#95;b&#63;c&#61;1&#38;d&#61;2</span>.' + ' And <span style="color:#6099C0">https&#58;&#47;&#47;y&#46;dev</span>');
    }
}
