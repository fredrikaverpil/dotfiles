import QtQuick
import QtTest
import "../plugins/bar/widgets/WorkspaceModel.js" as Workspaces
import "../Ui/compositors/NiriWorkspaces.js" as Niri

TestCase {
  name: "WorkspaceModel"

  function test_workspace_ids_retain_defaults_and_include_valid_live_workspaces() {
    compare(Workspaces.workspaceIds([8, 3, 8, 0, 11]), [1, 2, 3, 4, 5, 8])
    compare(Workspaces.workspaceIds(null), [1, 2, 3, 4, 5])
  }

  function test_niri_workspace_snapshots_map_global_ids_to_output_local_indexes() {
    const state = Niri.workspaceState([
      { id: 100, idx: 2 },
      { id: 42, idx: 1, is_focused: true },
    ], -1)
    compare(state, { ids: [1, 2], idxById: { 42: 1, 100: 2 }, focusedId: 1 })
    compare(Niri.windowCounts([{ workspace_id: 100 }, { workspace_id: 100 }, { workspace_id: 0 }], state.idxById), { 2: 2 })
  }

  function test_niri_events_request_window_refreshes_only_when_needed() {
    const state = { ids: [1], idxById: { 42: 1 }, focusedId: 1, windowCounts: { 1: 2 } }
    compare(Niri.eventResult(state, { WorkspaceActivated: { id: 42, focused: true } }).focusedId, 1)
    compare(Niri.eventResult(state, { WindowsChanged: { windows: [{ workspace_id: 42 }] } }).windowCounts, { 1: 1 })
    compare(Niri.eventResult(state, { WindowOpenedOrChanged: {} }).queryWindows, true)
    compare(Niri.eventResult(state, { WindowLayoutsChanged: {} }).queryWindows, true)
  }
}
