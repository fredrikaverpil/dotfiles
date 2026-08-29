// Quickshell-native org.freedesktop.Notifications service.
//
// This deliberately follows Omarchy's plugin path and public IPC shape. It
// keeps the user-facing core (toast stack, actions, DND and persisted history)
// while leaving its restart-persistence and image-archive machinery for later.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Wayland

import "components"
import "NotificationLogic.js" as NotificationLogic

Item {
  id: root

  property var shell: null
  readonly property var palette: shell ? shell.palette : ({ bg: "#1C1917", fg: "#B4BDC3", sel: "#3D4042", dim: "#403833", off: "#6E6864" })
  readonly property string statePath: Quickshell.env("HOME") + "/.local/state/wily-notifications.json"
  readonly property int historyLimit: 10

  property bool stateLoaded: false
  property bool doNotDisturb: false
  property bool historyShown: false
  property var popupRows: []
  property var historyRows: []
  property var live: ({})
  property int nextKey: 0

  function state() {
    return JSON.stringify({
      version: 1,
      doNotDisturb: doNotDisturb,
      history: historyRows
    }, null, 2) + "\n"
  }

  function saveState() {
    if (stateLoaded) stateFile.setText(state())
  }

  function loadState(raw) {
    var parsed = {}
    try {
      parsed = JSON.parse(String(raw || ""))
    } catch (error) {
      console.warn("notifications: ignoring invalid saved state:", error)
    }

    doNotDisturb = !!parsed.doNotDisturb
    historyRows = Array.isArray(parsed.history) ? parsed.history.slice(0, historyLimit) : []
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
    var rows = popupRows.slice()
    var index = rows.findIndex(function(row) { return row.key === record.key })
    if (index < 0) return
    rows[index] = record
    popupRows = rows
  }

  function addHistory(record) {
    if (record.transient) return

    var saved = {
      app: record.app,
      appIcon: record.appIcon,
      summary: record.summary,
      body: record.body,
      image: record.image,
      urgency: record.urgency,
      timestamp: record.timestamp
    }
    var rows = historyRows.slice()
    rows.unshift(saved)
    historyRows = rows.slice(0, historyLimit)
    saveState()
  }

  function finish(record) {
    if (!record || !live[record.key]) return

    delete live[record.key]
    popupRows = popupRows.filter(function(row) { return row.key !== record.key })
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

    // A replacing client updates this object in place. The original record is
    // therefore refreshed through its change signals rather than duplicated.
    for (var key in live) {
      if (live[key].notification === notification) {
        refresh(live[key])
        return
      }
    }

    record = recordFor(notification)

    // Critical messages remain visible; every other notification is recorded
    // silently while DND is enabled.
    if (doNotDisturb && notification.urgency !== NotificationUrgency.Critical) {
      addHistory(record)
      return
    }

    notification.tracked = true
    live[record.key] = record
    popupRows = [record].concat(popupRows)
    watch(record)
  }

  // `live` is the tracker: `finish` drops the key as soon as the server closes
  // the notification, so a stale record here means the object is already gone.
  // Invoking an action closes it, which is how the action paths reach this.
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
    // Copy before dismissing: Notification.closed mutates popupRows.
    var rows = popupRows.slice()
    for (var index = 0; index < rows.length; index++) dismiss(rows[index])
  }

  function showHistory() {
    historyShown = true
  }

  onDoNotDisturbChanged: saveState()

  // FileView does not emit loaded for a missing first-run file. Mark the
  // defaults writable immediately, then let a later load replace them when a
  // persisted state already exists.
  Component.onCompleted: {
    stateLoaded = true
    stateFile.reload()
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
      var normalized = String(value || "").toLowerCase()
      root.setDoNotDisturb(normalized === "true" || normalized === "1" || normalized === "on" || normalized === "yes")
      return dndState()
    }

    function showHistory(): string {
      root.showHistory()
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

  // Full-screen, click-through overlay. A fixed-size surface avoids the
  // compositor scaling a stale buffer while a toast is added or removed.
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

  PanelWindow {
    id: historyWindow
    visible: root.historyShown
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "wily-notification-history"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    MouseArea {
      anchors.fill: parent
      onClicked: root.historyShown = false
    }

    Rectangle {
      id: historyPanel
      anchors.centerIn: parent
      width: 620
      height: 560
      radius: 8
      color: root.palette.bg
      border.color: root.palette.dim
      border.width: 1

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        RowLayout {
          Layout.fillWidth: true

          Text {
            Layout.fillWidth: true
            text: "Notifications"
            color: root.palette.fg
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 18
          }

          Text {
            text: root.doNotDisturb ? "Do Not Disturb" : ""
            color: root.palette.off
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
          }

          Rectangle {
            width: clearLabel.implicitWidth + 14
            height: 26
            radius: 4
            color: clearMouse.containsMouse ? root.palette.sel : "transparent"
            border.color: root.palette.dim
            border.width: 1

            Text {
              id: clearLabel
              anchors.centerIn: parent
              text: "Clear"
              color: root.palette.fg
              font.family: "JetBrainsMono Nerd Font"
              font.pixelSize: 12
            }

            MouseArea {
              id: clearMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.clearHistory()
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          height: 1
          color: root.palette.dim
        }

        ListView {
          id: historyList
          Layout.fillWidth: true
          Layout.fillHeight: true
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
    }

    Item {
      anchors.fill: parent
      focus: root.historyShown

      Keys.onPressed: function(event) {
        if (event.key !== Qt.Key_Escape) return
        root.historyShown = false
        event.accepted = true
      }
    }
  }
}
