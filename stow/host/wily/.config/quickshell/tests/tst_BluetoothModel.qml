import QtQuick
import QtTest
import "../plugins/services/bluetooth/BluetoothModel.js" as Bluetooth

TestCase {
  name: "BluetoothModel"

  readonly property var deviceStates: ({ Disconnected: 0, Connected: 1, Disconnecting: 2, Connecting: 3 })

  function test_paired_devices_keep_paired_and_sort_connected_first() {
    const devices = [
      { name: "Zebra", paired: true, connected: true },
      { name: "Unpaired", paired: false, bonded: false, connected: false },
      { name: "Beta", paired: false, bonded: true, connected: false },
      { name: "", address: "AA:BB", paired: true, connected: false },
      null,
    ]

    const got = Bluetooth.pairedDevices(devices).map(device => Bluetooth.deviceName(device))

    compare(got, ["Zebra", "AA:BB", "Beta"])
    compare(Bluetooth.pairedDevices(undefined), [])
  }

  function test_device_status_and_action_follow_state() {
    const cases = [
      { state: deviceStates.Connected, battery: 0.8, status: "Connected · 80%", action: "Disconnect" },
      { state: deviceStates.Connected, battery: -1, status: "Connected", action: "Disconnect" },
      { state: deviceStates.Connecting, battery: -1, status: "Connecting…", action: "" },
      { state: deviceStates.Disconnecting, battery: 0.5, status: "Disconnecting…", action: "" },
      { state: deviceStates.Disconnected, battery: 0.5, status: "Paired", action: "Connect" },
    ]

    for (const c of cases) {
      const got = {
        status: Bluetooth.deviceStatus(c.state, deviceStates, c.battery),
        action: Bluetooth.deviceAction(c.state, deviceStates),
      }

      compare(got, { status: c.status, action: c.action })
    }
  }

  function test_icons() {
    const got = [
      Bluetooth.deviceIcon("audio-headset"),
      Bluetooth.deviceIcon("audio-card"),
      Bluetooth.deviceIcon("input-keyboard"),
      Bluetooth.deviceIcon("input-mouse"),
      Bluetooth.deviceIcon("input-gaming"),
      Bluetooth.deviceIcon("phone"),
      Bluetooth.deviceIcon(""),
      Bluetooth.barIcon(false, true, 1),
      Bluetooth.barIcon(true, false, 0),
      Bluetooth.barIcon(true, true, 0),
      Bluetooth.barIcon(true, true, 2),
    ]

    compare(got, ["󰋋", "󰓃", "󰌌", "󰍽", "󰊴", "󰏲", "󰂯", "󰂲", "󰂲", "󰂯", "󰂱"])
  }
}
