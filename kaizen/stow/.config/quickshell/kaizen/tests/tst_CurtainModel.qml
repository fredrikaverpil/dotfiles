import QtQuick
import QtTest
import "../modules/curtain/CurtainModel.js" as Curtain

TestCase {
    name: "CurtainModel"

    readonly property var hidden: ({
            active: false,
            awake: false
        })
    readonly property var black: ({
            active: true,
            awake: false
        })
    readonly property var awake: ({
            active: true,
            awake: true
        })

    function test_activation_starts_black_and_is_idempotent() {
        compare(Curtain.activate(hidden), black);
        compare(Curtain.activate(awake), awake);
        compare(Curtain.dismiss(awake), hidden);
        compare(Curtain.dismiss(hidden), hidden);
    }

    function test_input_wakes_the_prompt_only_while_the_curtain_is_up() {
        compare(Curtain.wake(black), awake);
        compare(Curtain.wake(hidden), hidden);
        compare(Curtain.wake(awake), awake);
        compare(Curtain.sleep(awake), black);
        compare(Curtain.sleep(black), black);
        compare(Curtain.sleep(hidden), hidden);
    }

    function test_prompt_and_backlight_are_mutually_exclusive() {
        compare(Curtain.shouldShowPrompt(awake), true);
        compare(Curtain.shouldShowPrompt(black), false);
        compare(Curtain.shouldShowPrompt(hidden), false);
        compare(Curtain.shouldDimBacklight(black), true);
        compare(Curtain.shouldDimBacklight(awake), false);
        compare(Curtain.shouldDimBacklight(hidden), false);
    }

    function test_timeout_never_blacks_out_an_in_flight_authentication() {
        compare(Curtain.shouldSleepOnTimeout(awake, false), true);
        compare(Curtain.shouldSleepOnTimeout(awake, true), false);
        compare(Curtain.shouldSleepOnTimeout(black, false), false);
        compare(Curtain.shouldSleepOnTimeout(hidden, false), false);
    }

    function test_restored_reads_a_previous_generation_or_nothing_data() {
        return [
            {
                tag: "up",
                text: '{"active":true,"savedBrightness":40}\n',
                want: {
                    active: true,
                    savedBrightness: 40
                }
            },
            {
                tag: "up without a backlight",
                text: '{"active":true,"savedBrightness":-1}\n',
                want: {
                    active: true,
                    savedBrightness: -1
                }
            },
            {
                tag: "down",
                text: '{"active":false,"savedBrightness":-1}\n',
                want: {
                    active: false,
                    savedBrightness: -1
                }
            },
            {
                tag: "brightness out of range",
                text: '{"active":true,"savedBrightness":140}',
                want: {
                    active: true,
                    savedBrightness: -1
                }
            },
            {
                tag: "brightness not an integer",
                text: '{"active":true,"savedBrightness":"40"}',
                want: {
                    active: true,
                    savedBrightness: -1
                }
            },
            {
                tag: "active not a boolean",
                text: '{"active":"true","savedBrightness":40}',
                want: {
                    active: false,
                    savedBrightness: 40
                }
            },
            {
                tag: "empty",
                text: "",
                want: {
                    active: false,
                    savedBrightness: -1
                }
            },
            {
                tag: "not JSON",
                text: "{",
                want: {
                    active: false,
                    savedBrightness: -1
                }
            },
            {
                tag: "null",
                text: "null",
                want: {
                    active: false,
                    savedBrightness: -1
                }
            }
        ];
    }

    function test_restored_reads_a_previous_generation_or_nothing(data) {
        compare(Curtain.restored(data.text), data.want);
    }
}
