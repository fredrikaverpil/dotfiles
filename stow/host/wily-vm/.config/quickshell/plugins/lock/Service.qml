
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland

import "../../Ui" as Ui
import "LockModel.js" as Model

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

  function authState() {
    return {
      lockRequested: lockRequested,
      authenticating: authenticating,
      pendingPassword: pendingPassword,
      enteredPassword: enteredPassword,
      failureMessage: failureMessage,
      failedAttempts: failedAttempts,
    }
  }

  function applyAuthState(state) {
    lockRequested = state.lockRequested
    authenticating = state.authenticating
    pendingPassword = state.pendingPassword
    enteredPassword = state.enteredPassword
    failureMessage = state.failureMessage
    failedAttempts = state.failedAttempts
  }

  function beginLock() {
    var transition = Model.begin(authState(), passwordPamConfigured, locked)
    if (!transition.started) return false
    if (locked) return true

    applyAuthState(transition.state)
    sessionLock.locked = true
    blankTimer.restart()
    return true
  }

  function finishUnlock() {
    if (passwordPam.active) passwordPam.abort()
    applyAuthState(Model.unlocked(authState()))
    blankTimer.stop()
    sessionLock.locked = false
    wake()
  }

  function submitPassword(password) {
    var next = Model.submit(authState(), password)
    if (!next) return

    applyAuthState(next)
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
    applyAuthState(Model.fail(authState()))
    wake()
  }

  // Repeated dpms-on forces a modeset and flashes the lock surface on every keypress.
  function dpms(on) {
    if (!Model.shouldSetDpms(dpmsProcess.running, blanked, on)) return
    blanked = !on
    dpmsProcess.command = Ui.Compositor.dpms(on)
    dpmsProcess.running = true
  }

  function wake() {
    dpms(true)
    if (lockRequested) blankTimer.restart()
  }

  function blank() {
    if (Model.shouldBlank(authState())) dpms(false)
  }

  WlSessionLock {
    id: sessionLock
    locked: false

    onLockStateChanged: {
      if (!locked && root.lockRequested) root.applyAuthState(Model.cancelled(root.authState()))
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
