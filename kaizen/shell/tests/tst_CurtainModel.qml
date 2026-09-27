import QtQuick
import QtTest
import "../plugins/curtain/CurtainModel.js" as Curtain

TestCase {
  name: "CurtainModel"

  readonly property var hidden: ({ active: false, awake: false })
  readonly property var black: ({ active: true, awake: false })
  readonly property var awake: ({ active: true, awake: true })

  function test_activation_starts_black_and_is_idempotent() {
    compare(Curtain.activate(hidden), black)
    compare(Curtain.activate(awake), awake)
    compare(Curtain.dismiss(awake), hidden)
    compare(Curtain.dismiss(hidden), hidden)
  }

  function test_input_wakes_the_prompt_only_while_the_curtain_is_up() {
    compare(Curtain.wake(black), awake)
    compare(Curtain.wake(hidden), hidden)
    compare(Curtain.wake(awake), awake)
    compare(Curtain.sleep(awake), black)
    compare(Curtain.sleep(black), black)
    compare(Curtain.sleep(hidden), hidden)
  }

  function test_prompt_and_backlight_are_mutually_exclusive() {
    compare(Curtain.shouldShowPrompt(awake), true)
    compare(Curtain.shouldShowPrompt(black), false)
    compare(Curtain.shouldShowPrompt(hidden), false)
    compare(Curtain.shouldDimBacklight(black), true)
    compare(Curtain.shouldDimBacklight(awake), false)
    compare(Curtain.shouldDimBacklight(hidden), false)
  }

  function test_timeout_never_blacks_out_an_in_flight_authentication() {
    compare(Curtain.shouldSleepOnTimeout(awake, false), true)
    compare(Curtain.shouldSleepOnTimeout(awake, true), false)
    compare(Curtain.shouldSleepOnTimeout(black, false), false)
    compare(Curtain.shouldSleepOnTimeout(hidden, false), false)
  }
}
