import QtQuick
import QtTest
import "../plugins/services/battery/BatteryModel.js" as Battery

TestCase {
  name: "BatteryModel"

  readonly property var deviceStates: ({ Charging: 1, Discharging: 2, FullyCharged: 4, PendingCharge: 5 })

  function battery(fields) {
    return Object.assign({ state: 2, fraction: 0.5, rate: 8, onBattery: true, timeToEmpty: 0, timeToFull: 0 }, fields)
  }

  function test_status_detects_threshold_holding_data() {
    return [
      { tag: "discharging", battery: battery({}), want: "On battery" },
      { tag: "pending charge", battery: battery({ state: 5, onBattery: false, rate: 0 }), want: "Holding" },
      { tag: "full below 99%", battery: battery({ state: 4, fraction: 0.8, onBattery: false, rate: 0 }), want: "Holding" },
      { tag: "idle charging at end", battery: battery({ state: 1, fraction: 0.8, onBattery: false, rate: 0.1 }), want: "Holding" },
      { tag: "idle charging below end", battery: battery({ state: 1, fraction: 0.6, onBattery: false, rate: 0.1 }), want: "Charging" },
      { tag: "charging", battery: battery({ state: 1, fraction: 0.8, onBattery: false, rate: 30 }), want: "Charging" },
      { tag: "full", battery: battery({ state: 4, fraction: 1, onBattery: false, rate: 0 }), want: "Full" },
      { tag: "unknown on AC", battery: battery({ state: 0, onBattery: false }), want: "Plugged in" },
    ]
  }

  function test_status_detects_threshold_holding(data) {
    verify(Battery.status(data.battery, deviceStates, 80) === data.want)
  }

  function test_icon_and_time_follow_power_flow_data() {
    return [
      { tag: "discharging", battery: battery({ fraction: 0.42, timeToEmpty: 7500 }), want: { icon: "󰁾", time: "2h 5m" } },
      { tag: "charging", battery: battery({ state: 1, fraction: 0.42, onBattery: false, timeToFull: 1800 }), want: { icon: "󰢝", time: "30m" } },
      { tag: "holding", battery: battery({ state: 5, fraction: 0.8, onBattery: false, timeToFull: 1800 }), want: { icon: "󰂂", time: "" } },
      { tag: "full", battery: battery({ state: 4, fraction: 1, onBattery: false, rate: 0 }), want: { icon: "󰂅", time: "" } },
    ]
  }

  function test_icon_and_time_follow_power_flow(data) {
    compare({
      icon: Battery.icon(data.battery, deviceStates, 80),
      time: Battery.timeRemaining(data.battery, deviceStates, 80),
    }, data.want)
  }

  function test_formatting() {
    compare({
      hours: Battery.formatDuration(3600),
      zero: Battery.formatDuration(0),
      rate: Battery.formatRate(-8.44),
      idle: Battery.formatRate(0.01),
      energy: Battery.formatEnergy(39.21, 46.68),
      noEnergy: Battery.formatEnergy(0, 0),
      health: Battery.formatHealth(true, 92.5),
      noHealth: Battery.formatHealth(false, 92.5),
      range: Battery.formatThreshold(75, 80),
      end: Battery.formatThreshold(0, 80),
      none: Battery.formatThreshold(0, 0),
    }, {
      hours: "1h",
      zero: "",
      rate: "8.4 W",
      idle: "--",
      energy: "39.2 / 46.7 Wh",
      noEnergy: "--",
      health: "93%",
      noHealth: "--",
      range: "75–80%",
      end: "80%",
      none: "--",
    })
  }

  function test_parse_sysfs_is_keyed_by_attribute() {
    compare(Battery.parseSysfs("charge_control_end_threshold:80\ncycle_count:60\nbogus\n"), { start: 0, end: 80, cycles: 60 })
  }

  function test_profiles_persist_per_power_source() {
    const saved = Battery.withProfile(Battery.loadedProfiles("not json"), "battery", "power-saver")
    compare(Battery.loadedProfiles(Battery.profilesText(saved)), { ac: "", battery: "power-saver" })
    compare({
      battery: Battery.profileFor(saved, "battery", Battery.profiles),
      ac: Battery.profileFor(saved, "ac", Battery.profiles),
      acWithoutPerformance: Battery.profileFor(saved, "ac", ["power-saver", "balanced"]),
    }, { battery: "power-saver", ac: "performance", acWithoutPerformance: "balanced" })
  }

  function test_low_battery_notifies_once_per_crossing() {
    var notified = ""
    var got = []
    for (const step of [[50, true], [10, true], [9, true], [5, true], [4, true], [4, false], [9, true]]) {
      const next = Battery.lowBattery(step[0], step[1], notified, 10, 5)
      notified = next.notified
      got.push(next.notify)
    }
    compare(got, ["", "low", "", "critical", "", "", "low"])
  }
}
