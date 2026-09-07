import QtQuick
import QtTest
import "../plugins/services/nightlight/NightlightModel.js" as Nightlight

TestCase {
  name: "NightlightModel"

  function test_nightlight_parses_daemon_output_and_time_zone_coordinates() {
    compare(Nightlight.temperatureFromOutput("temperature: 4000\n"), 4000)
    compare(Nightlight.temperatureFromOutput(""), null)
    compare(Nightlight.isNightlight(4000), true)
    compare(Nightlight.isNightlight(6500), false)
    compare(Nightlight.coordsFromZoneTab("+5920+01803"), { latitude: 59 + 20 / 60, longitude: 18 + 3 / 60 })
    compare(Nightlight.coordsFromZoneTab("invalid"), null)
  }

  function test_nightlight_solar_times_agree_with_known_stockholm_dates() {
    const stockholm = { latitude: 59 + 20 / 60, longitude: 18 + 3 / 60 }
    const midsummer = Nightlight.solarTimes(new Date("2024-06-21T12:00:00Z"), stockholm.latitude, stockholm.longitude)
    verify(midsummer)
    const apart = (a, b) => Math.abs(a.getTime() - b.getTime()) / 60000
    verify(apart(midsummer.sunrise, new Date("2024-06-21T01:31:00Z")) < 5)
    verify(apart(midsummer.sunset, new Date("2024-06-21T20:08:00Z")) < 5)
    compare(Nightlight.solarPeriod(new Date("2024-06-21T21:00:00Z"), stockholm.latitude, stockholm.longitude), "night")
    compare(Nightlight.solarPeriod(new Date("2024-06-21T12:00:00Z"), 78.2, 15.6), "day")
  }

  function test_nightlight_mode_state_controls_temperature_and_serialized_application() {
    compare(Nightlight.desiredTemperature("on", "day", 4000, 6500), 4000)
    compare(Nightlight.desiredTemperature("off", "night", 4000, 6500), 6500)
    compare(Number.isNaN(Nightlight.desiredTemperature("auto", "", 4000, 6500)), true)
    compare(Nightlight.modeState("on", "night"), { mode: "on", overridePeriod: "night" })
    compare(Nightlight.modeState("auto", "night"), { mode: "auto", overridePeriod: "" })
    compare(Nightlight.modeForPeriod("on", "day", "night"), "auto")
    compare(Nightlight.applyDecision(4000, 4000, false), "ignore")
    compare(Nightlight.applyDecision(4000, 6500, false), "start")
    compare(Nightlight.applyDecision(4000, 6500, true), "queue")
  }
}
