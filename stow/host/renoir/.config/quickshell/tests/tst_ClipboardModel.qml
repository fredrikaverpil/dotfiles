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
