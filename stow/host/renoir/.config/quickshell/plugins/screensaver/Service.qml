import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland

import "../lock" as LockUi
import "../lock/LockModel.js" as Auth
import "ScreensaverModel.js" as Model

// A privacy curtain, not a lock. It is a layer surface rather than a
// WlSessionLock so that toggling it off leaves a capturable desktop behind:
// wlr-screencopy (grim) sees whatever the compositor composites, and a session
// lock replaces that entirely. The trade is that the curtain dies with
// Quickshell, where a session lock would survive a crash.
Item {
  id: root

  property var shell: null
  property var brightnessService: null
  readonly property string userName: Quickshell.env("USER") || Quickshell.env("LOGNAME")
  readonly property int sleepAfterMs: 20000

  property bool passwordPamConfigured: false
  property bool active: false
  property bool awake: false
  property int savedBrightness: -1

  property bool authenticating: false
  property string pendingPassword: ""
  property string enteredPassword: ""
  property string failureMessage: ""
  property int failedAttempts: 0

  function curtainState() {
    return { active: active, awake: awake }
  }

  function applyCurtainState(state) {
    active = state.active
    awake = state.awake
    applyBacklight()
  }

  function authState() {
    return {
      lockRequested: active,
      authenticating: authenticating,
      pendingPassword: pendingPassword,
      enteredPassword: enteredPassword,
      failureMessage: failureMessage,
      failedAttempts: failedAttempts,
    }
  }

  function applyAuthState(state) {
    authenticating = state.authenticating
    pendingPassword = state.pendingPassword
    enteredPassword = state.enteredPassword
    failureMessage = state.failureMessage
    failedAttempts = state.failedAttempts
  }

  // Dim only while black, and restore before the prompt is drawn so it is
  // never rendered onto a dark panel. Internal panel only; the external
  // monitor is covered by the curtain itself, not by the backlight.
  function applyBacklight() {
    if (!brightnessService || !brightnessService.present) return
    if (Model.shouldDimBacklight(curtainState())) brightnessService.set(0)
    else if (savedBrightness >= 0) brightnessService.set(savedBrightness)
  }

  function show() {
    if (!passwordPamConfigured) return false
    if (active) return true

    if (brightnessService && brightnessService.present) savedBrightness = brightnessService.percent
    applyAuthState(Auth.reset(authState()))
    applyCurtainState(Model.activate(curtainState()))
    return true
  }

  function hide() {
    if (!active) return
    if (passwordPam.active) passwordPam.abort()
    sleepTimer.stop()
    applyAuthState(Auth.reset(authState()))
    applyCurtainState(Model.dismiss(curtainState()))
    savedBrightness = -1
  }

  // Mouse motion or any keypress reveals the prompt.
  function wake() {
    if (!active) return
    applyCurtainState(Model.wake(curtainState()))
    sleepTimer.restart()
  }

  function sleep() {
    if (!Model.shouldSleepOnTimeout(curtainState(), authenticating)) return
    applyAuthState(Auth.reset(authState()))
    applyCurtainState(Model.sleep(curtainState()))
  }

  function submitPassword(password) {
    var next = Auth.submit(authState(), password)
    if (!next) return

    applyAuthState(next)
    sleepTimer.restart()
    if (!passwordPam.start()) failAuthentication()
  }

  function respondToPasswordPrompt() {
    if (!authenticating || !passwordPam.active || !passwordPam.responseRequired) return
    passwordPam.respond(pendingPassword)
  }

  function failAuthentication() {
    applyAuthState(Auth.fail(authState()))
    wake()
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: surface
      required property var modelData

      // One surface owns the prompt and the keyboard; the rest are plain
      // black. Two focused TextInputs would fight over the seat.
      readonly property bool primary: modelData === Quickshell.screens[0]

      screen: modelData
      visible: root.active
      color: root.shell ? root.shell.palette.bg : "#1C1817"
      exclusionMode: ExclusionMode.Ignore
      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.namespace: "wily-screensaver"
      WlrLayershell.keyboardFocus: root.active && surface.primary
        ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.None

      LockUi.LockView {
        anchors.fill: parent
        visible: surface.primary && Model.shouldShowPrompt(root.curtainState())
        shell: root.shell
        authenticating: root.authenticating
        failureMessage: root.failureMessage
        password: root.enteredPassword
        inputEnabled: root.active && surface.primary && root.awake
        onPasswordEdited: function(value) { root.enteredPassword = value }
        onSubmitPassword: function(value) { root.submitPassword(value) }
        onClearFailureRequested: root.failureMessage = ""
        onWakeRequested: root.wake()
      }

      // Black state: catches the motion or keypress that reveals the prompt.
      MouseArea {
        anchors.fill: parent
        enabled: !root.awake
        visible: enabled
        hoverEnabled: true
        focus: surface.primary && !root.awake

        // A stationary pointer reports its position as soon as this enables;
        // only movement away from that first report wakes.
        readonly property int wakeDistance: 8
        property point origin: Qt.point(-1, -1)
        onEnabledChanged: origin = Qt.point(-1, -1)
        onPositionChanged: function(mouse) {
          if (origin.x < 0) {
            origin = Qt.point(mouse.x, mouse.y)
            return
          }
          if (Math.abs(mouse.x - origin.x) + Math.abs(mouse.y - origin.y) > wakeDistance) root.wake()
        }
        onClicked: root.wake()
        Keys.onPressed: function(event) {
          root.wake()
          event.accepted = true
        }
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
      if (!root.active) return
      if (result === PamResult.Success) root.hide()
      else root.failAuthentication()
    }
    onError: root.failAuthentication()
  }

  Timer {
    id: sleepTimer
    interval: root.sleepAfterMs
    repeat: false
    onTriggered: root.sleep()
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
    target: "screensaver"

    // `qs ipc call <target> show` is parsed as the CLI's own `show`.
    function open(): string {
      if (!root.passwordPamConfigured) return "missing-pam"
      return root.show() ? "shown" : "failed"
    }

    // The remote escape hatch: close, grim, open.
    function close(): string {
      root.hide()
      return "hidden"
    }

    function toggle(): string {
      if (root.active) {
        root.hide()
        return "hidden"
      }
      return root.show() ? "shown" : "failed"
    }

    function status(): string {
      return JSON.stringify({
        active: root.active,
        awake: root.awake,
        passwordPam: root.passwordPamConfigured,
        authenticating: root.authenticating
      })
    }
  }
}
