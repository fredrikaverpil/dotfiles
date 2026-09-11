import QtQuick
import QtTest
import "../plugins/services/weather/WeatherModel.js" as Weather

TestCase {
  name: "WeatherModel"

  function entry(time, temperature, symbol) {
    const data = { instant: { details: { air_temperature: temperature } } }
    if (symbol) data.next_1_hours = { summary: { symbol_code: symbol } }
    return { time: time, data: data }
  }

  function report(series) {
    return JSON.stringify({ properties: { timeseries: series } })
  }

  function test_coordinates_truncate_to_two_decimals_and_reject_rubbish() {
    verify(Weather.coordinate(57.7089) === 57.71)
    verify(Weather.coordinate("11.9746") === 11.97)
    verify(Weather.coordinate(-0.005) === -0)
    verify(Weather.coordinate("nowhere") === null)
    verify(Weather.coordinate(undefined) === null)
    verify(Weather.forecastUrl(57.7089, 11.9746)
      === "https://api.met.no/weatherapi/locationforecast/2.0/compact?lat=57.71&lon=11.97")
    verify(Weather.forecastUrl("nowhere", 11.97) === "")
  }

  function test_poll_interval_lands_after_expires_within_bounds() {
    const now = new Date("2026-09-07T19:00:00Z")
    // A minute past Expires, never on it: MET asks that we not re-request before it.
    verify(Weather.expiresInterval("Mon, 07 Sep 2026 19:30:00 GMT", now) === 31 * 60 * 1000)
    // A stale or absurd header must not busy-loop or stall the poll.
    verify(Weather.expiresInterval("Mon, 07 Sep 2026 19:01:00 GMT", now) === 5 * 60 * 1000)
    verify(Weather.expiresInterval("Mon, 07 Sep 2026 23:00:00 GMT", now) === 60 * 60 * 1000)
    // An expired header still waits the floor rather than retrying at once.
    verify(Weather.expiresInterval("Mon, 07 Sep 2026 18:00:00 GMT", now) === 5 * 60 * 1000)
    verify(Weather.expiresInterval("", now) === 30 * 60 * 1000)
    verify(Weather.expiresInterval("not a date", now) === 30 * 60 * 1000)
  }

  function test_symbol_codes_carry_their_own_day_and_night_state() {
    verify(Weather.isNight("clearsky_night") === true)
    verify(Weather.isNight("clearsky_polartwilight") === true)
    verify(Weather.isNight("clearsky_day") === false)
    verify(Weather.isNight("cloudy") === false)
    verify(Weather.icon("clearsky_day") !== Weather.icon("clearsky_night"))
    verify(Weather.icon("partlycloudy_day") !== Weather.icon("partlycloudy_night"))
    verify(Weather.icon("rain_day") === Weather.icon("rain_night"))
    verify(Weather.icon("") === "")
  }

  function test_kind_collapses_every_symbol_family() {
    verify(Weather.kind("clearsky_day") === "sun")
    verify(Weather.kind("fair_night") === "sun")
    verify(Weather.kind("partlycloudy_day") === "partly")
    verify(Weather.kind("cloudy") === "cloud")
    verify(Weather.kind("fog") === "fog")
    verify(Weather.kind("lightrainshowers_day") === "rain")
    verify(Weather.kind("heavysnowshowers_night") === "snow")
    verify(Weather.kind("lightsleet") === "snow")
    // Thunder wins over the precipitation it falls with.
    verify(Weather.kind("heavyrainandthunder") === "storm")
    verify(Weather.kind("snowshowersandthunder_day") === "storm")
    verify(Weather.kind("") === "")
  }

  function test_condition_text_survives_mets_own_misspellings() {
    verify(Weather.condition("clearsky_day") === "Clear sky")
    verify(Weather.condition("partlycloudy_night") === "Partly cloudy")
    verify(Weather.condition("fog") === "Fog")
    verify(Weather.condition("rain") === "Rain")
    verify(Weather.condition("lightrain") === "Light rain")
    verify(Weather.condition("heavyrainshowers_day") === "Heavy rain showers")
    verify(Weather.condition("sleetshowersandthunder_night") === "Sleet showers and thunder")
    // MET's own legend writes these two with a stray "s".
    verify(Weather.condition("lightssleetshowersandthunder_day") === "Light sleet showers and thunder")
    verify(Weather.condition("lightssnowshowersandthunder_night") === "Light snow showers and thunder")
    verify(Weather.condition("") === "")
  }

  function test_temperatures_round_and_ignore_missing_values() {
    verify(Weather.temperature(16.6) === "17°")
    verify(Weather.temperature(-0.4) === "0°")
    verify(Weather.temperature(null) === "")
    verify(Weather.temperature("") === "")
  }

  function test_current_conditions_come_from_the_hour_under_way() {
    const raw = report([
      entry("2026-09-07T19:00:00Z", 16.6, "cloudy"),
      entry("2026-09-07T20:00:00Z", 15.2, "rainandthunder"),
      entry("2026-09-07T21:00:00Z", 13.4, "clearsky_night"),
    ])
    // MET leaves the finished 19:00 hour at the head of the timeseries.
    const parsed = Weather.parse(raw, new Date("2026-09-07T20:09:00Z"))
    verify(parsed.current.symbol === "rainandthunder")
    verify(parsed.current.temperature === 15.2)
    verify(parsed.days.length === 0)
  }

  function test_current_conditions_fall_back_to_the_first_entry() {
    const raw = report([entry("2026-09-07T19:00:00Z", 16.6, "cloudy")])
    const parsed = Weather.parse(raw, new Date("2026-09-07T18:30:00Z"))
    verify(parsed.current.symbol === "cloudy")
    verify(parsed.current.temperature === 16.6)
  }

  function test_unusable_responses_parse_to_null() {
    verify(Weather.parse("not json") === null)
    verify(Weather.parse("{}") === null)
    verify(Weather.parse(report([])) === null)
    // An entry without instant details cannot describe the current sky.
    verify(Weather.parse(report([{ time: "2026-09-07T19:00:00Z", data: {} }])) === null)
  }

  // Entries sit at midday UTC so the local calendar day is the same in any
  // timezone this test might run in.
  function test_daily_extremes_group_by_day_and_skip_today() {
    const raw = report([
      entry("2026-09-07T12:00:00Z", 16.6, "cloudy"),
      entry("2026-09-08T12:00:00Z", 19.7, "lightrain"),
      entry("2026-09-08T12:00:01Z", 15.6, null),
      entry("2026-09-09T12:00:00Z", 18.7, "clearsky_day"),
      entry("2026-09-10T12:00:00Z", 16.5, "snow"),
      entry("2026-09-11T12:00:00Z", 12.0, "rain"),
    ])
    const parsed = Weather.parse(raw, new Date("2026-09-07T12:00:00Z"))

    verify(parsed.days.length === 3)
    compare(parsed.days.map(day => day.date), ["2026-09-08", "2026-09-09", "2026-09-10"])
    compare(parsed.days.map(day => day.name), ["Tue", "Wed", "Thu"])
    verify(parsed.days[0].maximum === 19.7)
    verify(parsed.days[0].minimum === 15.6)
    verify(parsed.days[0].symbol === "lightrain")
    verify(parsed.days[1].maximum === 18.7)
    verify(parsed.days[1].minimum === 18.7)
  }
}
