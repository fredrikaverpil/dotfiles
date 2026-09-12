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
