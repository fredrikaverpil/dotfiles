import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

import "RecordingModel.js" as Model

Item {
  id: root

  readonly property string statePath: Quickshell.env("HOME") + "/.local/state/wily-recording.json"
  readonly property string directory: Quickshell.env("HOME") + "/Videos"

  // Saved choices. An empty camera or mic means off; unavailable ones fall back.
  property string monitor: ""
  property string camera: ""
  property string mic: "default_input"
  property bool desktop: true
  property bool stateLoaded: false

  property var cameras: []
  readonly property var monitors: Quickshell.screens.map(screen => screen.name)
  readonly property var mics: Pipewire.nodes
    ? Pipewire.nodes.values.filter(node => node && node.audio && !node.isSink && !node.isStream)
    : []

  readonly property string activeMonitor: Model.pick(monitors, monitor, monitors[0] || "")
  readonly property string activeCamera: Model.pick(cameras.map(entry => entry.path), camera, "")
  readonly property string activeMic: Model.pick(["", "default_input"].concat(mics.map(node => node.name)),
    mic, "default_input")

  property int countdown: 0
  property bool paused: false
  property int seconds: 0
  property string file: ""
  readonly property bool recording: recorder.running
  readonly property bool busy: recording || countdown > 0

  function refreshCameras() { if (!busy) cameraList.running = true }

  function start() {
    if (busy || !activeMonitor) return
    countdown = 3
    countdownTimer.restart()
  }

  function cancel() {
    countdownTimer.stop()
    countdown = 0
  }

  function stop() {
    if (countdown > 0) cancel()
    else if (recording) recorder.signal(2) // SIGINT finalizes the file.
  }

  function togglePause() {
    if (!recording) return
    recorder.signal(12) // SIGUSR2
    paused = !paused
  }

  function launch() {
    file = directory + "/" + Model.fileName(new Date())
    const options = { monitor: activeMonitor, camera: activeCamera, mic: activeMic, desktop: desktop }
    recorder.command = ["sh", "-c", 'mkdir -p "$0" && exec "$@"', directory].concat(Model.command(options, file))
    seconds = 0
    paused = false
    recorder.running = true
  }

  function saveState() {
    if (!stateLoaded) return
    stateFile.setText(JSON.stringify({ version: 1, monitor: monitor, camera: camera, mic: mic, desktop: desktop }) + "\n")
  }

  onMonitorChanged: saveState()
  onCameraChanged: saveState()
  onMicChanged: saveState()
  onDesktopChanged: saveState()

  Component.onCompleted: stateFile.reload()

  FileView {
    id: stateFile
    path: root.statePath
    atomicWrites: true
    printErrors: false
    onLoaded: {
      try {
        const saved = JSON.parse(String(text() || ""))
        root.monitor = saved.monitor || ""
        root.camera = saved.camera || ""
        root.mic = typeof saved.mic === "string" ? saved.mic : "default_input"
        root.desktop = saved.desktop !== false
      } catch (error) {}
      root.stateLoaded = true
    }
    onLoadFailed: root.stateLoaded = true
  }

  Timer {
    id: countdownTimer
    interval: 1000
    repeat: true
    onTriggered: {
      root.countdown -= 1
      if (root.countdown > 0) return
      countdownTimer.stop()
      root.launch()
    }
  }

  Timer {
    interval: 1000
    repeat: true
    running: root.recording && !root.paused
    onTriggered: root.seconds += 1
  }

  Process {
    id: cameraList
    command: ["sh", "-c",
      'gpu-screen-recorder --list-v4l2-devices | cut -d"|" -f1 | sort -u | while read -r path; do '
      + 'printf "%s|%s\\n" "$path" "$(cat "/sys/class/video4linux/${path##*/}/name")"; done']
    stdout: StdioCollector {
      onStreamFinished: root.cameras = Model.parseCameras(text)
    }
  }

  Process {
    id: recorder
    stderr: StdioCollector { id: recorderErrors }
    onExited: function (exitCode) {
      root.paused = false
      if (exitCode === 0) {
        Quickshell.execDetached(["wl-copy", root.file])
        Quickshell.execDetached(["notify-send", "-a", "Recording", "Recording saved", root.file])
        Quickshell.execDetached(["xdg-open", root.file])
      } else {
        const lines = String(recorderErrors.text || "").trim().split("\n")
        Quickshell.execDetached(["notify-send", "-a", "Recording", "-u", "critical",
          "Recording failed", lines[lines.length - 1] || "exit code " + exitCode])
      }
    }
  }

  Component.onDestruction: if (recording) recorder.signal(2)
}
