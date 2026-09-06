import { createRequire } from "node:module"
import { assertEquals } from "jsr:@std/assert"

const Workspaces = createRequire(import.meta.url)("../plugins/bar/widgets/WorkspaceModel.js")

Deno.test("workspace ids retain defaults and include valid live workspaces", () => {
  assertEquals(Workspaces.workspaceIds([8, 3, 8, 0, 11]), [1, 2, 3, 4, 5, 8])
  assertEquals(Workspaces.workspaceIds(null), [1, 2, 3, 4, 5])
})

Deno.test("niri workspace snapshots map global IDs to output-local indexes", () => {
  const state = Workspaces.workspaceState([
    { id: 100, idx: 2 },
    { id: 42, idx: 1, is_focused: true },
  ], -1)
  assertEquals(state, { ids: [1, 2], idxById: { 42: 1, 100: 2 }, focusedId: 1 })
  assertEquals(Workspaces.windowCounts([{ workspace_id: 100 }, { workspace_id: 100 }, { workspace_id: 0 }], state.idxById), { 2: 2 })
  assertEquals(Workspaces.occupied({ 2: 1 }, 2), true)
  assertEquals(Workspaces.occupied({}, 2), false)
})

Deno.test("niri events request window refreshes only when needed", () => {
  const state = { ids: [1], idxById: { 42: 1 }, focusedId: 1, windowCounts: { 1: 2 } }
  assertEquals(Workspaces.eventResult(state, { WorkspaceActivated: { id: 42, focused: true } }).focusedId, 1)
  assertEquals(Workspaces.eventResult(state, { WindowsChanged: { windows: [{ workspace_id: 42 }] } }).windowCounts, { 1: 1 })
  assertEquals(Workspaces.eventResult(state, { WindowOpenedOrChanged: {} }).queryWindows, true)
  assertEquals(Workspaces.eventResult(state, { WindowLayoutsChanged: {} }).queryWindows, true)
})
