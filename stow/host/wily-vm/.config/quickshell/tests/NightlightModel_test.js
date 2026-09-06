import { createRequire } from "node:module"
import { assert, assertEquals } from "jsr:@std/assert"

const Nightlight = createRequire(import.meta.url)("../plugins/services/nightlight/NightlightModel.js")

Deno.test("nightlight parses daemon output and time-zone coordinates", () => {
  assertEquals(Nightlight.temperatureFromOutput("temperature: 4000\n"), 4000)
  assertEquals(Nightlight.temperatureFromOutput(""), null)
  assertEquals(Nightlight.isNightlight(4000), true)
  assertEquals(Nightlight.isNightlight(6500), false)
  assertEquals(Nightlight.coordsFromZoneTab("+5920+01803"), { latitude: 59 + 20 / 60, longitude: 18 + 3 / 60 })
  assertEquals(Nightlight.coordsFromZoneTab("invalid"), null)
})

Deno.test("nightlight solar times agree with known Stockholm dates", () => {
  const stockholm = { latitude: 59 + 20 / 60, longitude: 18 + 3 / 60 }
  const midsummer = Nightlight.solarTimes(new Date("2024-06-21T12:00:00Z"), stockholm.latitude, stockholm.longitude)
  assert(midsummer)
  const apart = (a, b) => Math.abs(a.getTime() - b.getTime()) / 60000
  assert(apart(midsummer.sunrise, new Date("2024-06-21T01:31:00Z")) < 5)
  assert(apart(midsummer.sunset, new Date("2024-06-21T20:08:00Z")) < 5)
  assertEquals(Nightlight.solarPeriod(new Date("2024-06-21T21:00:00Z"), stockholm.latitude, stockholm.longitude), "night")
  assertEquals(Nightlight.solarPeriod(new Date("2024-06-21T12:00:00Z"), 78.2, 15.6), "day")
})

Deno.test("nightlight mode state controls temperature and serialized application", () => {
  assertEquals(Nightlight.desiredTemperature("on", "day", 4000, 6500), 4000)
  assertEquals(Nightlight.desiredTemperature("off", "night", 4000, 6500), 6500)
  assertEquals(Number.isNaN(Nightlight.desiredTemperature("auto", "", 4000, 6500)), true)
  assertEquals(Nightlight.modeState("on", "night"), { mode: "on", overridePeriod: "night" })
  assertEquals(Nightlight.modeState("auto", "night"), { mode: "auto", overridePeriod: "" })
  assertEquals(Nightlight.modeForPeriod("on", "day", "night"), "auto")
  assertEquals(Nightlight.applyDecision(4000, 4000, false), "ignore")
  assertEquals(Nightlight.applyDecision(4000, 6500, false), "start")
  assertEquals(Nightlight.applyDecision(4000, 6500, true), "queue")
})
