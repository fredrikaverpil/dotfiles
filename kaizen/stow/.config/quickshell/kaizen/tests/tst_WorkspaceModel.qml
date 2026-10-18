import QtQuick
import QtTest
import "../modules/bar/widgets/WorkspaceModel.js" as Workspaces
import "../Ui/compositors/NiriWorkspaces.js" as Niri
import "../Ui/compositors/UmbrielWorkspaces.js" as Umbriel

TestCase {
    name: "WorkspaceModel"

    function test_workspace_ids_retain_defaults_and_include_valid_live_workspaces() {
        compare(Workspaces.workspaceIds([8, 3, 8, 0, 11]), [1, 2, 3, 4, 5, 8]);
        compare(Workspaces.workspaceIds(null), [1, 2, 3, 4, 5]);
    }

    function test_niri_workspaces_are_per_output() {
        const workspaces = {
            100: {
                id: 100,
                idx: 2,
                output: "DP-1",
                is_active: true
            },
            42: {
                id: 42,
                idx: 1,
                output: "DP-1",
                is_active: false
            },
            7: {
                id: 7,
                idx: 1,
                output: "eDP-1",
                is_active: true
            }
        };
        compare(Niri.ids(workspaces, "DP-1"), [1, 2]);
        compare(Niri.ids(workspaces, "eDP-1"), [1]);
        compare(Niri.activeId(workspaces, "DP-1"), 2);
        compare(Niri.activeId(workspaces, "HDMI-A-1"), -1);

        const counts = Niri.windowCounts({
            1: {
                id: 1,
                workspace_id: 7
            },
            2: {
                id: 2,
                workspace_id: 7
            },
            3: {
                id: 3,
                workspace_id: null
            }
        });
        compare(counts, {
            7: 2
        });
        verify(Niri.occupied(workspaces, counts, "eDP-1", 1) === true);
        verify(Niri.occupied(workspaces, counts, "DP-1", 1) === false);
    }

    function test_umbriel_snapshots_are_per_output() {
        const list = [
            {
                output: "DP-1",
                index: 2,
                active: true,
                window_count: 0
            },
            {
                output: "DP-1",
                index: 1,
                active: false,
                window_count: 3
            },
            {
                output: "eDP-1",
                index: 1,
                active: true,
                window_count: 0
            }
        ];
        compare(Umbriel.ids(list, "DP-1"), [1, 2]);
        compare(Umbriel.ids(list, "HDMI-A-1"), []);
        compare(Umbriel.activeId(list, "DP-1"), 2);
        compare(Umbriel.activeId(list, "HDMI-A-1"), -1);
        compare(Umbriel.occupied(list, "DP-1", 1), true);
        compare(Umbriel.occupied(list, "DP-1", 2), false);
        compare(Umbriel.occupied(list, "eDP-1", 1), false);
    }
}
