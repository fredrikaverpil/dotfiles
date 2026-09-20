import QtQuick
import Quickshell.Bluetooth

import "BluetoothModel.js" as Model

Item {
  id: root

  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property bool available: adapter !== null
  readonly property bool powered: available && adapter.enabled
  readonly property var devices: Model.pairedDevices(adapter ? adapter.devices.values : [])
  readonly property int connectedCount: devices.filter(device => device.connected).length
  readonly property string icon: Model.barIcon(available, powered, connectedCount)

  function togglePower() {
    if (adapter) adapter.enabled = !adapter.enabled
  }

  function battery(device) { return device.batteryAvailable ? device.battery : -1 }

  function deviceStatus(device) {
    return Model.deviceStatus(device.state, BluetoothDeviceState, battery(device))
  }

  function deviceAction(device) { return Model.deviceAction(device.state, BluetoothDeviceState) }

  function deviceIcon(device) { return Model.deviceIcon(device.icon) }

  function toggleConnection(device) {
    if (device.connected) device.disconnect()
    else device.connect()
  }

  function status() {
    return JSON.stringify({
      available: available,
      powered: powered,
      devices: devices.map(device => ({
        name: Model.deviceName(device),
        address: device.address,
        status: deviceStatus(device),
      })),
    })
  }
}
