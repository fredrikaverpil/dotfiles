
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Wayland

import "../../Ui" as Ui
import "components"
import "NotificationLogic.js" as NotificationLogic
import "NotificationModel.js" as Model

Item {
  id: root

  property var shell: null
  readonly property var palette: shell ? shell.palette : ({ bg: "#1C1917", fg: "#B4BDC3", sel: "#3D4042", dim: "#403833", off: "#6E6864" }) // qmllint disable property-override
  readonly property string statePath: Quickshell.env("HOME") + "/.local/state/wily-notifications.json"
  readonly property int historyLimit: 10
  readonly property string soundPath: "/run/current-system/sw/share/sounds/freedesktop/stereo/message.oga"
  readonly property real soundVolume: 0.4

  property bool stateLoaded: false
  property bool doNotDisturb: false
  readonly property alias historyShown: historyPanel.shown
  property var popupRows: []
  property var historyRows: []
  property var live: ({})
  property int nextKey: 0

  function stateText() { return Model.stateText(doNotDisturb, historyRows) }

  function saveState() {
    if (stateLoaded) stateFile.setText(stateText())
  }

  function loadState(raw) {
    var saved = Model.loadedState(raw, historyLimit)
    if (!saved.valid) console.warn("notifications: ignoring invalid saved state")
    doNotDisturb = saved.doNotDisturb
    historyRows = saved.history
    stateLoaded = true
  }

  function recordFor(notification, existing) {
    var record = NotificationLogic.snapshotOf(notification)
    record.key = existing ? existing.key : String(++nextKey)
    record.notification = notification
    record.duration = NotificationLogic.durationFor(notification, NotificationUrgency.Low, NotificationUrgency.Critical)
    record.transient = notification.transient
    return record
  }

  function replacePopup(record) {
    popupRows = Model.replacePopup(popupRows, record)
  }

  function addHistory(record) {
    if (!record || record.transient) return
    historyRows = Model.historyWith(historyRows, record, historyLimit)
    saveState()
  }

  function finish(record) {
    if (!record || !live[record.key]) return

    delete live[record.key]
    popupRows = Model.withoutRecord(popupRows, record.key)
    addHistory(record)
  }

  function refresh(record) {
    if (!record || !live[record.key] || !record.notification) return

    var refreshed = recordFor(record.notification, record)
    live[record.key] = refreshed
    replacePopup(refreshed)
  }

  function watch(record) {
    var notification = record.notification
    notification.closed.connect(function() { root.finish(record) })

    var refresh = function() { root.refresh(record) }
    notification.appNameChanged.connect(refresh)
    notification.appIconChanged.connect(refresh)
    notification.summaryChanged.connect(refresh)
    notification.bodyChanged.connect(refresh)
    notification.imageChanged.connect(refresh)
    notification.urgencyChanged.connect(refresh)
    notification.expireTimeoutChanged.connect(refresh)
  }

  function handleNotification(notification) {
    var record

    for (var key in live) {
      if (live[key].notification === notification) {
        refresh(live[key])
        return
      }
    }

    record = recordFor(notification)

    if (doNotDisturb && notification.urgency !== NotificationUrgency.Critical) {
      addHistory(record)
      return
    }

    notification.tracked = true
    live[record.key] = record
    popupRows = [record].concat(popupRows)
    watch(record)
    sound.startDetached()
  }

  function dismiss(record) {
    if (!record || !record.notification || !live[record.key]) return
    record.notification.dismiss()
  }

  function expire(record) {
    if (!record || !record.notification || !live[record.key]) return
    record.notification.expire()
  }

  function defaultAction(record) {
    if (!record || !record.notification) return

    var actions = record.notification.actions || []
    for (var index = 0; index < actions.length; index++) {
      if (actions[index].identifier === "default") {
        actions[index].invoke()
        break
      }
    }
    dismiss(record)
  }

  function action(record, selectedAction) {
    if (!record || !selectedAction) return
    selectedAction.invoke()
    dismiss(record)
  }

  function setDoNotDisturb(value) {
    doNotDisturb = !!value
  }

  function clearHistory() {
    historyRows = []
    saveState()
  }

  function dismissAll() {
    var rows = popupRows.slice()
    for (var index = 0; index < rows.length; index++) dismiss(rows[index])
  }

  function close() { historyPanel.close() }

  function showHistory() { historyPanel.open() }

  function toggleHistory() { historyPanel.toggle() }

  onDoNotDisturbChanged: saveState()

  Component.onCompleted: {
    stateLoaded = true
    stateFile.reload()
  }

  Process {
    id: sound
    command: ["pw-play", "--volume", String(root.soundVolume), root.soundPath]
  }

  FileView {
    id: stateFile
    path: root.statePath
    atomicWrites: true
    printErrors: false
    onLoaded: root.loadState(text())
  }

  NotificationServer {
    id: server
    keepOnReload: false
    bodySupported: true
    bodyMarkupSupported: false
    bodyHyperlinksSupported: false
    bodyImagesSupported: false
    imageSupported: true
    actionsSupported: true
    actionIconsSupported: false
    inlineReplySupported: false
    persistenceSupported: false

    onNotification: function(notification) {
      root.handleNotification(notification)
    }
  }

  IpcHandler {
    target: "notifications"

    function dndState(): string { return root.doNotDisturb ? "on" : "off" }
    function isDnd(): string { return dndState() }

    function toggleDnd(): string {
      root.setDoNotDisturb(!root.doNotDisturb)
      return dndState()
    }

    function setDnd(value: string): string {
      root.setDoNotDisturb(Model.dndValue(value))
      return dndState()
    }

    function showHistory(): string {
      root.showHistory()
      return "ok"
    }

    function toggleHistory(): string {
      root.toggleHistory()
      return "ok"
    }

    function clear(): string {
      root.clearHistory()
      return "ok"
    }

    function dismissAll(): string {
      root.dismissAll()
      return "ok"
    }

    function dismissOne(): string {
      if (root.popupRows.length === 0) return "none"
      root.dismiss(root.popupRows[0])
      return "ok"
    }

    function invokeLast(): string {
      if (root.popupRows.length === 0) return "none"
      root.defaultAction(root.popupRows[0])
      return "ok"
    }
  }

  PanelWindow {
    id: popupWindow
    visible: root.popupRows.length > 0
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    mask: Region { item: popupColumn }
    WlrLayershell.namespace: "wily-notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Column {
      id: popupColumn
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.topMargin: 40
      anchors.rightMargin: 16
      width: 400
      spacing: 8

      Repeater {
        model: root.popupRows

        delegate: NotificationCard {
          required property var modelData

          width: popupColumn.width
          palette: root.palette
          row: modelData
          notification: modelData.notification
          toast: true
          duration: modelData.duration
          onCloseRequested: root.dismiss(modelData)
          onInvokeRequested: root.defaultAction(modelData)
          onActionRequested: function(selectedAction) { root.action(modelData, selectedAction) }
          onExpired: root.expire(modelData)
        }
      }
    }
  }

  Ui.Panel {
    id: historyPanel

    shell: root.shell
    cardWidth: 620
    cardHeight: 560
    keyNavigation: true

    RowLayout {
      id: historyHeader
      width: parent.width
      spacing: 8

      Text {
        Layout.fillWidth: true
        text: "Notifications"
        color: root.palette.fg
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 18
      }

      HeaderButton {
        label: "Do Not Disturb"
        active: root.doNotDisturb
        onActivated: root.setDoNotDisturb(!root.doNotDisturb)
      }

      HeaderButton {
        label: "Clear"
        onActivated: root.clearHistory()
      }
    }

    Rectangle {
      id: historySeparator
      width: parent.width
      height: 1
      color: root.palette.dim
    }

    ListView {
      id: historyList
      width: parent.width
      height: parent.height - historyHeader.height - historySeparator.height - 2 * historyPanel.contentSpacing
      clip: true
      spacing: 8
      model: root.historyRows

      delegate: NotificationCard {
        required property var modelData
        required property int index

        width: historyList.width
        palette: root.palette
        row: modelData
        toast: false
        onCloseRequested: {
          var rows = root.historyRows.slice()
          rows.splice(index, 1)
          root.historyRows = rows
          root.saveState()
        }
        onInvokeRequested: {}
      }

      Text {
        anchors.centerIn: parent
        visible: historyList.count === 0
        text: "No recent notifications"
        color: root.palette.off
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 14
      }
    }
  }

  component HeaderButton: Rectangle {
    id: button

    property string label: ""
    property bool active: false
    signal activated

    implicitWidth: buttonLabel.implicitWidth + 14
    implicitHeight: 26
    radius: 4
    color: active || buttonMouse.containsMouse ? root.palette.sel : "transparent"
    border.color: button.activeFocus ? root.palette.fg : root.palette.dim
    border.width: 1

    activeFocusOnTab: true
    Keys.onReturnPressed: button.activated()
    Keys.onEnterPressed: button.activated()
    Keys.onSpacePressed: button.activated()

    Text {
      id: buttonLabel
      anchors.centerIn: parent
      text: button.label
      color: root.palette.fg
      font.family: "JetBrainsMono Nerd Font"
      font.pixelSize: 12
    }

    MouseArea {
      id: buttonMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: button.activated()
    }
  }
}
