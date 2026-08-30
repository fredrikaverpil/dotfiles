// Quickshell-native idle policy, following Omarchy's service location.
// IdleMonitor honours idle inhibitors, so no second daemon such as hypridle.

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "IdleModel.js" as IdleModel

Item {
  id: root

  property var lockService: null
  readonly property string statePath: Quickshell.env("HOME") + "/.local/state/wily-idle.json"
  readonly property int lockAfterSeconds: 300

  property bool stateLoaded: false
  property bool enabled: true

  function setEnabled(value) {
    enabled = !!value
  }

  function saveState() {
    if (stateLoaded) stateFile.setText(JSON.stringify({ version: 1, enabled: enabled }) + "\n")
  }

  function lockNow() {
    if (!enabled || !lockService) return
    lockService.beginLock()
  }

  onEnabledChanged: saveState()

  // A missing state file is a normal first run, not a reason to make the
  // user's first toggle disappear when Quickshell next restarts.
  Component.onCompleted: {
    stateLoaded = true
    stateFile.reload()
  }

  FileView {
    id: stateFile
    path: root.statePath
    atomicWrites: true
    printErrors: false
    onLoaded: {
      try {
        var parsed = JSON.parse(String(text() || ""))
        root.enabled = parsed.enabled !== false
      } catch (error) {
        root.enabled = true
      }
      root.stateLoaded = true
    }
  }

  IdleMonitor {
    id: idleMonitor
    enabled: root.enabled
    timeout: root.lockAfterSeconds
    respectInhibitors: true
    onIsIdleChanged: {
      if (isIdle) root.lockNow()
      else if (root.lockService && root.lockService.locked) root.lockService.wake()
    }
  }

  IpcHandler {
    target: "idle"

    function status(): string {
      return JSON.stringify({
        enabled: root.enabled,
        idle: idleMonitor.isIdle,
        lockAfterSeconds: root.lockAfterSeconds
      })
    }

    function enable(): string {
      root.setEnabled(true)
      return "enabled"
    }

    function disable(): string {
      root.setEnabled(false)
      return "disabled"
    }

    function toggle(): string {
      root.setEnabled(!root.enabled)
      return root.enabled ? "enabled" : "disabled"
    }
  }
}
