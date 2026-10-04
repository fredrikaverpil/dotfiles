import QtQuick
import QtTest
import "../modules/services/mirror/MirrorModel.js" as Mirror

TestCase {
    name: "MirrorModel"

    function test_state_round_trips_the_description() {
        const raw = "MainPID=4242\nDescription=" + Mirror.description("eDP-1", "DP-1") + "\n";
        compare(Mirror.state(raw), {
            pid: 4242,
            source: "eDP-1",
            target: "DP-1"
        });
    }

    function test_state_is_off_without_a_running_unit() {
        const off = {
            pid: 0,
            source: "",
            target: ""
        };
        compare(Mirror.state("MainPID=0\nDescription=kaizen-mirror.service\n"), off);
        compare(Mirror.state("MainPID=0\nDescription=" + Mirror.description("eDP-1", "DP-1") + "\n"), off);
        compare(Mirror.state(""), off);
    }
}
