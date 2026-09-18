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

  function test_niri_workspace_snapshots_are_per_output() {
    const state = Niri.workspaceState([
      { id: 100, idx: 2, output: "DP-1", is_active: true },
      { id: 42, idx: 1, output: "DP-1" },
      { id: 7, idx: 1, output: "eDP-1", is_active: true },
    ])
    compare(state, {
      workspaces: { 7: { idx: 1, output: "eDP-1" }, 42: { idx: 1, output: "DP-1" }, 100: { idx: 2, output: "DP-1" } },
      activeByOutput: { "DP-1": 2, "eDP-1": 1 },
    })
    compare(Niri.ids(state.workspaces, "DP-1"), [1, 2])
    compare(Niri.ids(state.workspaces, "eDP-1"), [1])

    const counts = Niri.windowCounts([{ workspace_id: 7 }, { workspace_id: 7 }, { workspace_id: null }])
    compare(counts, { 7: 2 })
    verify(Niri.occupied(state.workspaces, counts, "eDP-1", 1) === true)
    verify(Niri.occupied(state.workspaces, counts, "DP-1", 1) === false)
  }

  function test_niri_activation_changes_only_its_output() {
    const state = {
      workspaces: { 42: { idx: 1, output: "DP-1" }, 100: { idx: 2, output: "DP-1" }, 7: { idx: 1, output: "eDP-1" } },
      activeByOutput: { "DP-1": 2, "eDP-1": 1 },
      windowCounts: {},
    }
    compare(Niri.eventResult(state, { WorkspaceActivated: { id: 42, focused: true } }).activeByOutput, { "DP-1": 1, "eDP-1": 1 })
    compare(state.activeByOutput, { "DP-1": 2, "eDP-1": 1 })
    compare(Niri.eventResult(state, { WorkspaceActivated: { id: 999, focused: true } }).activeByOutput, state.activeByOutput)
  }

  function test_niri_events_request_window_refreshes_only_when_needed() {
    const state = { workspaces: { 42: { idx: 1, output: "DP-1" } }, activeByOutput: {}, windowCounts: { 42: 2 } }
    compare(Niri.eventResult(state, { WindowsChanged: { windows: [{ workspace_id: 42 }] } }).windowCounts, { 42: 1 })
    compare(Niri.eventResult(state, { WindowOpenedOrChanged: {} }).queryWindows, true)
    compare(Niri.eventResult(state, { WindowLayoutsChanged: {} }).queryWindows, true)
    compare(Niri.eventResult(state, { WorkspaceActivated: { id: 42 } }).queryWindows, false)
  }
}
