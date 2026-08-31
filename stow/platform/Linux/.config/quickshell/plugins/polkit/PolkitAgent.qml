// Theme-aware Polkit agent. This retains Omarchy's native Quickshell approach
// and path while omitting its ThinkPad fingerprint and clamshell handling.

import QtQuick
import Quickshell
import Quickshell.Services.Polkit
import Quickshell.Wayland

import "PolkitModel.js" as PolkitModel

Item {
  id: root

  property var shell: null
  readonly property var palette: shell ? shell.palette : ({ bg: "#1C1917", fg: "#B4BDC3", sel: "#3D4042", dim: "#403833", off: "#6E6864" })

  property bool closing: false
  property bool submitted: false
  property bool failed: false
  property string message: ""
  property string prompt: ""
  property string supplementary: ""
  property bool responseRequired: false

  readonly property bool dialogVisible: polkitAgent.isActive || closing

  function syncFromFlow() {
    var flow = polkitAgent.flow
    if (!flow) return

    message = String(flow.message || "Authentication is needed")
    prompt = String(flow.inputPrompt || "Password")
    supplementary = String(flow.supplementaryMessage || "")
    responseRequired = !!flow.isResponseRequired
    failed = !!flow.failed
    if (responseRequired) submitted = false
  }

  function focusInput() {
    if (dialogVisible && responseRequired && !submitted) passwordInput.forceActiveFocus()
  }

  function beginFlow() {
    closing = false
    submitted = false
    failed = false
    passwordInput.text = ""
    syncFromFlow()
    Qt.callLater(focusInput)
  }

  function submit() {
    var flow = polkitAgent.flow
    if (!flow || !flow.isResponseRequired || submitted) return

    submitted = true
    flow.submit(passwordInput.text)
    passwordInput.text = ""
  }

  function cancel() {
    var flow = polkitAgent.flow
    closing = true
    closeTimer.restart()
    if (flow) flow.cancelAuthenticationRequest()
  }

  function finish() {
    closing = true
    closeTimer.restart()
  }

  Timer {
    id: closeTimer
    interval: 250
    repeat: false
    onTriggered: {
      root.closing = false
      root.submitted = false
      root.failed = false
      root.message = ""
      root.prompt = ""
      root.supplementary = ""
      passwordInput.text = ""
    }
  }

  PolkitAgent {
    id: polkitAgent
    path: "/org/wily/PolkitAgent"

    onAuthenticationRequestStarted: root.beginFlow()
    onIsActiveChanged: {
      if (isActive) root.syncFromFlow()
      else if (!root.closing) root.finish()
    }
    onIsRegisteredChanged: {
      if (isRegistered) console.log("wily polkit agent registered")
      else console.warn("wily polkit agent is not registered; another agent may be running")
    }
  }

  Connections {
    target: polkitAgent.flow

    function onIsResponseRequiredChanged() {
      root.syncFromFlow()
      if (!polkitAgent.flow || !polkitAgent.flow.isResponseRequired) passwordInput.text = ""
      Qt.callLater(root.focusInput)
    }

    function onInputPromptChanged() { root.syncFromFlow() }
    function onSupplementaryMessageChanged() { root.syncFromFlow() }
    function onFailedChanged() {
      root.syncFromFlow()
      if (root.failed) {
        root.submitted = false
        passwordInput.text = ""
        Qt.callLater(root.focusInput)
      }
    }
    function onAuthenticationSucceeded() { root.finish() }
    function onAuthenticationRequestCancelled() { root.finish() }
  }

  PanelWindow {
    id: panel
    visible: root.dialogVisible
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "wily-polkit"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Rectangle {
      anchors.fill: parent
      color: root.shell && root.shell.dark ? "#991C1917" : "#99F0EDEC"
    }

    Rectangle {
      id: card
      anchors.centerIn: parent
      width: Math.min(420, parent.width - 48)
      height: content.implicitHeight + 32
      radius: 8
      color: root.palette.bg
      border.color: root.failed ? "#C94F46" : root.palette.fg
      border.width: 1

      Column {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: 16
        spacing: 12

        Text {
          width: parent.width
          text: PolkitModel.authorizationLabel(root.message)
          textFormat: Text.PlainText
          wrapMode: Text.WordWrap
          color: root.palette.fg
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 16
        }

        Text {
          width: parent.width
          visible: root.supplementary.length > 0
          text: root.supplementary
          textFormat: Text.PlainText
          wrapMode: Text.WordWrap
          color: root.failed ? "#C94F46" : root.palette.off
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 13
        }

        Rectangle {
          width: parent.width
          height: 46
          radius: 4
          color: root.palette.sel
          border.color: root.failed ? "#C94F46" : root.palette.dim
          border.width: 1

          TextInput {
            id: passwordInput
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            verticalAlignment: TextInput.AlignVCenter
            enabled: root.responseRequired && !root.submitted
            echoMode: TextInput.Password
            passwordCharacter: "●"
            passwordMaskDelay: 0
            color: root.palette.fg
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 16

            onAccepted: root.submit()
            Keys.onPressed: function(event) {
              if (event.key === Qt.Key_Escape) {
                root.cancel()
                event.accepted = true
              }
            }
          }

          Text {
            anchors.fill: passwordInput
            visible: passwordInput.text.length === 0
            text: root.submitted ? "Checking…" : root.prompt
            color: root.palette.off
            font: passwordInput.font
            verticalAlignment: Text.AlignVCenter
          }
        }

        Text {
          width: parent.width
          text: "Enter to authorize · Esc to cancel"
          color: root.palette.off
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 11
        }
      }
    }

    Item {
      anchors.fill: parent
      focus: root.dialogVisible && !passwordInput.activeFocus

      Keys.onPressed: function(event) {
        if (event.key !== Qt.Key_Escape) return
        root.cancel()
        event.accepted = true
      }
    }
  }
}
