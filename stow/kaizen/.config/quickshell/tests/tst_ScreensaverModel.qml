import QtQuick
import QtTest
import "../plugins/screensaver/ScreensaverModel.js" as Screensaver

TestCase {
  name: "ScreensaverModel"

  readonly property var hidden: ({ active: false, awake: false })
  readonly property var black: ({ active: true, awake: false })
  readonly property var awake: ({ active: true, awake: true })

  function test_activation_starts_black_and_is_idempotent() {
    compare(Screensaver.activate(hidden), black)
    compare(Screensaver.activate(awake), awake)
    compare(Screensaver.dismiss(awake), hidden)
    compare(Screensaver.dismiss(hidden), hidden)
  }

  function test_input_wakes_the_prompt_only_while_the_curtain_is_up() {
    compare(Screensaver.wake(black), awake)
    compare(Screensaver.wake(hidden), hidden)
    compare(Screensaver.wake(awake), awake)
    compare(Screensaver.sleep(awake), black)
    compare(Screensaver.sleep(black), black)
    compare(Screensaver.sleep(hidden), hidden)
  }

  function test_prompt_and_backlight_are_mutually_exclusive() {
    compare(Screensaver.shouldShowPrompt(awake), true)
    compare(Screensaver.shouldShowPrompt(black), false)
    compare(Screensaver.shouldShowPrompt(hidden), false)
    compare(Screensaver.shouldDimBacklight(black), true)
    compare(Screensaver.shouldDimBacklight(awake), false)
    compare(Screensaver.shouldDimBacklight(hidden), false)
  }

  function test_timeout_never_blacks_out_an_in_flight_authentication() {
    compare(Screensaver.shouldSleepOnTimeout(awake, false), true)
    compare(Screensaver.shouldSleepOnTimeout(awake, true), false)
    compare(Screensaver.shouldSleepOnTimeout(black, false), false)
    compare(Screensaver.shouldSleepOnTimeout(hidden, false), false)
  }
}
