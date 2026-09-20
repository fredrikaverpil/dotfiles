import QtQuick
import QtTest
import "../plugins/services/clipboard/ClipboardModel.js" as Model

TestCase {
  name: "ClipboardModel"

  function test_add_data() {
    return [
      { tag: "first", history: [], text: "a", limit: 50,
        want: [{ text: "a", at: 3 }] },
      { tag: "newest first", history: [{ text: "a", at: 1 }], text: "b", limit: 50,
        want: [{ text: "b", at: 3 }, { text: "a", at: 1 }] },
      { tag: "repeat moves to top", history: [{ text: "b", at: 2 }, { text: "a", at: 1 }], text: "a", limit: 50,
        want: [{ text: "a", at: 3 }, { text: "b", at: 2 }] },
      { tag: "empty ignored", history: [{ text: "a", at: 1 }], text: "", limit: 50,
        want: [{ text: "a", at: 1 }] },
      { tag: "capped", history: [{ text: "b", at: 2 }, { text: "a", at: 1 }], text: "c", limit: 2,
        want: [{ text: "c", at: 3 }, { text: "b", at: 2 }] },
    ]
  }

  function test_add(data) {
    compare(Model.add(data.history, data.text, 3, data.limit), data.want)
  }

  function test_remove_at_data() {
    const history = [{ text: "b", at: 2 }, { text: "a", at: 1 }]
    return [
      { tag: "newest", history: history, index: 0, want: [{ text: "a", at: 1 }] },
      { tag: "oldest", history: history, index: 1, want: [{ text: "b", at: 2 }] },
      { tag: "past the end", history: history, index: 2, want: history },
      { tag: "negative", history: history, index: -1, want: history },
    ]
  }

  function test_remove_at(data) {
    compare(Model.removeAt(data.history, data.index), data.want)
  }

  function test_preview_data() {
    return [
      { tag: "plain", text: "hello", want: "hello" },
      { tag: "multiline", text: "  one\n\ttwo  \n", want: "one two" },
      { tag: "bounded", text: "x".repeat(1000), want: "x".repeat(500) },
    ]
  }

  function test_preview(data) {
    verify(Model.preview(data.text) === data.want)
  }
}
