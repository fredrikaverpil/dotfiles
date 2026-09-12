import QtQuick
import QtTest
import "../plugins/services/recording/RecordingModel.js" as Recording

TestCase {
  name: "RecordingModel"

  function test_command_data() {
    return [
      {
        tag: "screen only",
        options: { monitor: "DP-1", camera: "", mic: "", desktop: false },
        want: ["gpu-screen-recorder", "-w", "DP-1", "-f", "30", "-o", "/v/a.mp4"],
      },
      {
        tag: "camera and merged audio",
        options: { monitor: "eDP-1", camera: "/dev/video2", mic: "default_input", desktop: true },
        want: ["gpu-screen-recorder", "-w",
          "monitor:eDP-1|v4l2:/dev/video2;halign=end;valign=end;width=20%", "-f", "30",
          "-a", "default_output|default_input", "-ac", "aac", "-o", "/v/a.mp4"],
      },
      {
        tag: "region with camera",
        options: { region: { x: 100, y: 50.4, width: 800, height: 600 }, camera: "/dev/video0", mic: "",
          desktop: false },
        want: ["gpu-screen-recorder", "-w", "region|v4l2:/dev/video0;halign=end;valign=end;width=20%",
          "-region", "800x600+100+50", "-f", "30", "-o", "/v/a.mp4"],
      },
      {
        tag: "mic only",
        options: { monitor: "DP-1", camera: "", mic: "alsa_input.usb", desktop: false },
        want: ["gpu-screen-recorder", "-w", "DP-1", "-f", "30",
          "-a", "alsa_input.usb", "-ac", "aac", "-o", "/v/a.mp4"],
      },
    ]
  }

  function test_command(data) {
    compare(Recording.command(data.options, "/v/a.mp4"), data.want)
  }

  readonly property var screens: [
    { name: "DP-1", x: 0, y: 0, width: 2560, height: 1440 },
    { name: "eDP-1", x: 2560, y: 540, width: 1600, height: 900 },
  ]

  function test_parse_region_data() {
    return [
      { tag: "valid", text: " 800x600+2700+-5 ", want: { x: 2700, y: -5, width: 800, height: 600 } },
      { tag: "whole monitor", text: "0x0+10+10", want: { x: 10, y: 10, width: 0, height: 0 } },
      { tag: "garbage", text: "800x600", want: null },
      { tag: "empty", text: "", want: null },
    ]
  }

  function test_parse_region(data) {
    compare(Recording.parseRegion(data.text), data.want)
  }

  function test_screen_at_data() {
    return [
      { tag: "centre on DP-1", rect: { x: 2400, y: 0, width: 200, height: 100 }, want: "DP-1" },
      { tag: "centre on eDP-1", rect: { x: 2500, y: 600, width: 200, height: 100 }, want: "eDP-1" },
      { tag: "centre off screen", rect: { x: 3000, y: 0, width: 100, height: 100 }, want: "" },
    ]
  }

  function test_screen_at(data) {
    const screen = Recording.screenAt(screens, data.rect)
    verify((screen ? screen.name : "") === data.want)
  }

  function test_clamp_region_data() {
    return [
      { tag: "inside unchanged", rect: { x: 2600, y: 600, width: 100, height: 100 },
        want: { x: 2600, y: 600, width: 100, height: 100 } },
      { tag: "pushed inside", rect: { x: 4100, y: 1400, width: 100, height: 100 },
        want: { x: 4060, y: 1340, width: 100, height: 100 } },
      { tag: "shrunk to screen", rect: { x: 2000, y: 0, width: 5000, height: 5 },
        want: { x: 2560, y: 540, width: 1600, height: 16 } },
    ]
  }

  function test_clamp_region(data) {
    compare(Recording.clampRegion(data.rect, screens[1]), data.want)
  }

  function test_initial_region_data() {
    return [
      { tag: "saved kept", saved: { x: 2600, y: 600, width: 100, height: 100 },
        want: { x: 2600, y: 600, width: 100, height: 100 } },
      { tag: "none centres on first", saved: null, want: { x: 640, y: 360, width: 1280, height: 720 } },
      { tag: "off screen centres on first", saved: { x: 9000, y: 0, width: 10, height: 10 },
        want: { x: 640, y: 360, width: 1280, height: 720 } },
    ]
  }

  function test_initial_region(data) {
    compare(Recording.initialRegion(data.saved, screens), data.want)
  }

  function test_next_screen_region_data() {
    return [
      { tag: "to eDP-1", rect: { x: 0, y: 0, width: 400, height: 300 },
        want: { x: 3160, y: 840, width: 400, height: 300 } },
      { tag: "wraps and fits", rect: { x: 2560, y: 540, width: 1600, height: 900 },
        want: { x: 480, y: 270, width: 1600, height: 900 } },
    ]
  }

  function test_next_screen_region(data) {
    compare(Recording.nextScreenRegion(data.rect, screens), data.want)
  }

  function test_span_region() {
    compare(Recording.spanRegion(300, 50, 100, 200), { x: 100, y: 50, width: 200, height: 150 })
  }

  function test_file_name() {
    verify(Recording.fileName(new Date(2026, 8, 2, 7, 5, 9)) === "recording-2026-09-02_07-05-09.mp4")
  }

  function test_elapsed_data() {
    return [
      { tag: "zero", seconds: 0, want: "00:00" },
      { tag: "minutes", seconds: 83, want: "01:23" },
      { tag: "hours", seconds: 3725, want: "1:02:05" },
    ]
  }

  function test_elapsed(data) {
    verify(Recording.elapsed(data.seconds) === data.want)
  }

  function test_parse_cameras() {
    compare(Recording.parseCameras(
      "/dev/video0|Integrated Camera: Integrated C\n/dev/video2|Logitech StreamCam\nnoise\n"), [
      { path: "/dev/video0", name: "Integrated Camera" },
      { path: "/dev/video2", name: "Logitech StreamCam" },
    ])
  }

  function test_pick_data() {
    return [
      { tag: "saved present", saved: "b", want: "b" },
      { tag: "saved gone", saved: "z", want: "fallback" },
    ]
  }

  function test_pick(data) {
    verify(Recording.pick(["a", "b"], data.saved, "fallback") === data.want)
  }

  function test_step_data() {
    return [
      { tag: "forward", current: "a", delta: 1, want: "b" },
      { tag: "wraps forward", current: "c", delta: 1, want: "a" },
      { tag: "wraps back", current: "a", delta: -1, want: "c" },
      { tag: "unknown starts at first", current: "z", delta: 1, want: "b" },
    ]
  }

  function test_step(data) {
    verify(Recording.step(["a", "b", "c"], data.current, data.delta) === data.want)
  }
}
