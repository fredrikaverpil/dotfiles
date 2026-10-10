import QtQuick
import QtTest
import "../Ui/Jsonc.js" as Jsonc

TestCase {
    name: "Jsonc"

    function test_comments_and_trailing_commas_are_dropped() {
        const cases = [
            {
                text: '// lead\n[1, /* inline */ 2] // trail',
                want: [1, 2]
            },
            {
                text: '{\n  "a": 1, // one\n  "b": [2, 3,],\n}',
                want: {
                    a: 1,
                    b: [2, 3]
                }
            },
            {
                text: '[1, // last\n /* none */ ]',
                want: [1]
            },
        ];
        for (const c of cases)
            compare(Jsonc.parse(c.text), c.want, c.text);
    }

    function test_strings_keep_comment_markers_commas_and_escapes() {
        compare(Jsonc.parse('{"url": "https://x.org/a,]", "re": "^a\\\\/\\\\/b$", "q": "say \\"//\\", ok"}'), {
            url: "https://x.org/a,]",
            re: "^a\\/\\/b$",
            q: 'say "//", ok'
        });
    }

    function test_line_comments_keep_their_newlines_and_block_comments_run_to_the_end() {
        verify(Jsonc.strip("[1, // x\n2]") === "[1, \n2]");
        verify(Jsonc.strip("[1 /* unterminated") === "[1 ");
    }

    function test_invalid_json_throws() {
        let thrown = false;
        try {
            Jsonc.parse("[1,, 2]");
        } catch (error) {
            thrown = true;
        }
        verify(thrown);
    }
}
