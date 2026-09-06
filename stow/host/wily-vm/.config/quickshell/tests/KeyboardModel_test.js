
import { createRequire } from "node:module"
import { assertEquals } from "jsr:@std/assert"

const KeyboardModel = createRequire(import.meta.url)("../plugins/services/keyboard/KeyboardModel.js")

Deno.test("currentIndex", async (t) => {
  const cases = [
    { name: "niri reports the index directly", niri: true, text: '{"names":["English (US)","Swedish"],"current_idx":1}', want: 1 },
    { name: "niri on the first layout", niri: true, text: '{"names":["English (US)"],"current_idx":0}', want: 0 },
    { name: "niri without the field", niri: true, text: '{"names":[]}', want: -1 },
    { name: "hyprland prefers the main keyboard", niri: false, text: '{"keyboards":[{"name":"power-button","active_layout_index":0},{"name":"at-translated-set-2","main":true,"active_layout_index":1}]}', want: 1 },
    { name: "hyprland falls back to the first", niri: false, text: '{"keyboards":[{"name":"at-translated-set-2","active_layout_index":1}]}', want: 1 },
    { name: "hyprland with no keyboards", niri: false, text: '{"keyboards":[]}', want: -1 },
    { name: "hyprland without the field", niri: false, text: '{"keyboards":[{"main":true}]}', want: -1 },
    { name: "null index is not zero", niri: true, text: '{"current_idx":null}', want: -1 },
    { name: "a killed query returns nothing", niri: true, text: "", want: -1 },
    { name: "unparseable output", niri: false, text: "hyprctl: not running", want: -1 },
    { name: "an array is not an answer", niri: false, text: "[]", want: -1 },
  ]
  for (const c of cases) {
    await t.step(c.name, () => assertEquals(KeyboardModel.currentIndex(c.text, c.niri), c.want))
  }
})
