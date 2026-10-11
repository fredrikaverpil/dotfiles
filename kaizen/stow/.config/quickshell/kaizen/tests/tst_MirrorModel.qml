import QtQuick
import QtTest
import "../modules/services/mirror/MirrorModel.js" as Mirror

TestCase {
    name: "MirrorModel"

    function test_mirrors_round_trip_the_description() {
        const raw = "Description=" + Mirror.description("eDP-1", "DP-1") + "\nMainPID=4242\n\n" + "Description=" + Mirror.description("eDP-1", "HDMI-A-1") + "\nMainPID=4343\n";
        compare(Mirror.mirrors(raw), [
            {
                pid: 4242,
                source: "eDP-1",
                target: "DP-1"
            },
            {
                pid: 4343,
                source: "eDP-1",
                target: "HDMI-A-1"
            }
        ]);
    }

    function test_mirrors_skip_units_without_a_running_mirror() {
        compare(Mirror.mirrors(""), []);
        compare(Mirror.mirrors("Description=kaizen-mirror-DP-1.service\nMainPID=4242\n"), []);
        compare(Mirror.mirrors("Description=" + Mirror.description("eDP-1", "DP-1") + "\nMainPID=0\n"), []);
    }

    function test_can_mirror_refuses_chains() {
        const list = [
            {
                pid: 1,
                source: "eDP-1",
                target: "DP-1"
            }
        ];
        compare([Mirror.canMirror(list, "eDP-1", "HDMI-A-1"), Mirror.canMirror(list, "HDMI-A-1", "DP-1"), Mirror.canMirror(list, "DP-1", "HDMI-A-1"), Mirror.canMirror(list, "HDMI-A-1", "eDP-1"), Mirror.canMirror(list, "eDP-1", "eDP-1"), Mirror.canMirror(list, "", "DP-1")], [true, true, false, false, false, false]);
    }
}
