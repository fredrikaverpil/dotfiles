// Quickshell-native session lock. The component layout and IPC target mirror
// Omarchy's lock plugin while intentionally deferring its fingerprint and
// orphaned-session-lock recovery paths until the ThinkPad work begins.

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland

import "../../Ui" as Ui

Item {
  id: root

  property var shell: null
  readonly property string userName: Quickshell.env("USER") || Quickshell.env("LOGNAME")

  property bool passwordPamConfigured: false
  property bool lockRequested: false
  property bool authenticating: false
  property string pendingPassword: ""
  property string enteredPassword: ""
  property string failureMessage: ""
  property int failedAttempts: 0
  property bool blanked: false

  readonly property bool locked: lockRequested || sessionLock.locked || sessionLock.secure

  function beginLock() {
    if (!passwordPamConfigured) return false
    if (locked) return true

    enteredPassword = ""
    pendingPassword = ""
    failureMessage = ""
    failedAttempts = 0
    lockRequested = true
    sessionLock.locked = true
    // Nothing else arms the blank timer at lock time, so a lock nobody touches
    // would never blank the output. Not `wake()`: its dpms(true) drives output
    // churn while the lock surface is still being acquired, which crashes the
    // shell with "Tried to show lockscreen surfaces without active lock".
    blankTimer.restart()
    return true
  }

  function finishUnlock() {
    if (passwordPam.active) passwordPam.abort()
    lockRequested = false
    authenticating = false
    pendingPassword = ""
    enteredPassword = ""
    failureMessage = ""
    blankTimer.stop()
    sessionLock.locked = false
    wake()
  }

  function submitPassword(password) {
    var value = String(password || "")
    if (!lockRequested || authenticating || value.length === 0) return

    pendingPassword = value
    enteredPassword = ""
    failureMessage = ""
    authenticating = true
    wake()

    if (!passwordPam.start()) failAuthentication()
    else Qt.callLater(respondToPasswordPrompt)
  }

  function respondToPasswordPrompt() {
    if (!authenticating || !passwordPam.active || !passwordPam.responseRequired) return
    passwordPam.respond(pendingPassword)
  }

  function failAuthentication() {
    if (!lockRequested) return
    authenticating = false
    pendingPassword = ""
    enteredPassword = ""
    failedAttempts += 1
    failureMessage = "Authentication failed (" + failedAttempts + ")"
    wake()
  }

  function dpms(on) {
    // Turning on an output that is already on forces a modeset, and wake() runs
    // on every keystroke — so an unguarded dispatch flashes the lock screen
    // black under typing. "on" is only needed while blanked, "off" only while
    // not.
    if (dpmsProcess.running || blanked !== on) return
    blanked = !on
    dpmsProcess.command = Ui.Compositor.dpms(on)
    dpmsProcess.running = true
  }

  function wake() {
    dpms(true)
    if (lockRequested) blankTimer.restart()
  }

  function blank() {
    if (lockRequested && !authenticating) dpms(false)
  }

  WlSessionLock {
    id: sessionLock
    locked: false

    onLockStateChanged: {
      // A compositor-side unlock outside the normal PAM success path must not
      // leave stale authentication state in this long-lived shell process.
      if (!locked && root.lockRequested) {
        root.lockRequested = false
        root.authenticating = false
        root.pendingPassword = ""
        root.enteredPassword = ""
        root.failureMessage = ""
      }
    }

    WlSessionLockSurface {
      color: root.shell ? root.shell.palette.bg : "#1C1917"

      LockView {
        anchors.fill: parent
        shell: root.shell
        authenticating: root.authenticating
        failureMessage: root.failureMessage
        password: root.enteredPassword
        inputEnabled: root.lockRequested
        onPasswordEdited: function(value) { root.enteredPassword = value }
        onSubmitPassword: function(value) { root.submitPassword(value) }
        onClearFailureRequested: root.failureMessage = ""
        onWakeRequested: root.wake()
      }
    }
  }

  PamContext {
    id: passwordPam
    config: "wily-lock"
    user: root.userName

    onResponseRequiredChanged: root.respondToPasswordPrompt()
    onPamMessage: root.respondToPasswordPrompt()
    onCompleted: function(result) {
      root.authenticating = false
      root.pendingPassword = ""
      if (!root.lockRequested) return
      if (result === PamResult.Success) root.finishUnlock()
      else root.failAuthentication()
    }
    onError: root.failAuthentication()
  }

  // The lock is taken after five idle minutes. Once secure, leave another five
  // minutes before blanking the output; any lock-screen interaction wakes it.
  Timer {
    id: blankTimer
    interval: 300000
    repeat: false
    onTriggered: root.blank()
  }

  Process {
    id: dpmsProcess
  }

  FileView {
    path: "/etc/pam.d/wily-lock"
    watchChanges: true
    printErrors: false
    onLoaded: root.passwordPamConfigured = true
    onLoadFailed: root.passwordPamConfigured = false
    onFileChanged: reload()
  }

  IpcHandler {
    target: "lock"

    function lock(): string {
      if (!root.passwordPamConfigured) return "missing-pam"
      return root.beginLock() ? "ok" : "failed"
    }

    function isLocked(): string {
      return root.locked ? "true" : "false"
    }

    function status(): string {
      return JSON.stringify({
        locked: root.locked,
        requested: root.lockRequested,
        secure: sessionLock.secure,
        passwordPam: root.passwordPamConfigured,
        authenticating: root.authenticating
      })
    }
  }
}
