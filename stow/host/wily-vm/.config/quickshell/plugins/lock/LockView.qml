// Password lock surface. The shape follows Omarchy's LockView component, but
// uses this shell's wallpaper and palette rather than Omarchy's theme module.

import QtQuick

Item {
  id: root

  property var shell: null
  property bool authenticating: false
  property string failureMessage: ""
  property string password: ""
  property bool inputEnabled: true

  signal passwordEdited(string value)
  signal submitPassword(string value)
  signal clearFailureRequested()
  signal wakeRequested()

  readonly property var palette: shell ? shell.palette : ({ bg: "#1C1917", fg: "#B4BDC3", sel: "#3D4042", dim: "#403833", off: "#6E6864" })

  function focusPassword() {
    if (inputEnabled && !authenticating) passwordInput.forceActiveFocus()
  }

  function clearPassword() {
    passwordInput.text = ""
  }

  onInputEnabledChanged: Qt.callLater(focusPassword)
  onAuthenticatingChanged: {
    if (!authenticating) Qt.callLater(focusPassword)
  }
  Component.onCompleted: Qt.callLater(focusPassword)

  Rectangle {
    anchors.fill: parent
    color: root.palette.bg

    Image {
      anchors.fill: parent
      source: root.shell && root.shell.wallpaper ? "file://" + root.shell.wallpaper : ""
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
    }

    Rectangle {
      anchors.fill: parent
      color: root.shell && root.shell.dark ? "#D91C1917" : "#D9F0EDEC"
    }

    MouseArea {
      anchors.fill: parent
      onClicked: {
        root.wakeRequested()
        root.focusPassword()
      }
      onPositionChanged: root.wakeRequested()
    }

    Rectangle {
      id: field
      anchors.centerIn: parent
      width: Math.min(380, parent.width - 48)
      height: 64
      radius: 8
      color: root.palette.bg
      border.color: root.failureMessage.length > 0 ? "#C94F46" : root.palette.fg
      border.width: 2

      TextInput {
        id: passwordInput
        anchors.fill: parent
        anchors.leftMargin: 18
        anchors.rightMargin: 18
        verticalAlignment: TextInput.AlignVCenter
        horizontalAlignment: TextInput.AlignHCenter
        enabled: root.inputEnabled && !root.authenticating
        echoMode: TextInput.Password
        passwordCharacter: "●"
        passwordMaskDelay: 0
        color: root.palette.fg
        selectionColor: root.palette.sel
        selectedTextColor: root.palette.fg
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: text.length > 0 ? 24 : 18
        cursorVisible: activeFocus && text.length > 0

        onTextChanged: {
          root.passwordEdited(text)
          if (text.length > 0 && root.failureMessage.length > 0) root.clearFailureRequested()
        }

        onAccepted: {
          var submitted = text
          text = ""
          if (submitted.length > 0) root.submitPassword(submitted)
        }

        Keys.onPressed: function(event) {
          root.wakeRequested()
          if (event.key === Qt.Key_Escape || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_U)) {
            passwordInput.text = ""
            event.accepted = true
          }
        }
      }

      Text {
        anchors.fill: passwordInput
        visible: passwordInput.text.length === 0
        text: root.authenticating ? "Checking…" : (root.failureMessage || "Enter password")
        color: root.authenticating ? root.palette.fg : (root.failureMessage ? "#C94F46" : root.palette.off)
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 18
        font.italic: root.failureMessage.length > 0
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
      }
    }
  }
}
