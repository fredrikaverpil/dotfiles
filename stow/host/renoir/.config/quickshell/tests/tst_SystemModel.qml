import QtQuick
import QtTest
import "../plugins/services/system/SystemModel.js" as System

TestCase {
  name: "SystemModel"

  function test_cpu_usage_between_samples_data() {
    return [
      {
        tag: "aggregate line only",
        previous: "cpu  10 0 10 70 10 0 0 0 0 0\ncpu0 5 0 5 35 5 0 0 0 0 0\nintr 1 2\n",
        current: "cpu  60 0 10 120 10 0 0 0 0 0\ncpu0 55 0 5 35 5 0 0 0 0 0\nintr 3 4\n",
        want: 50,
      },
      { tag: "no previous sample", previous: "", current: "cpu  1 0 0 1 0 0 0 0 0 0\n", want: 0 },
      { tag: "no time passed", previous: "cpu  1 0 0 1 0 0 0 0 0 0\n", current: "cpu  1 0 0 1 0 0 0 0 0 0\n", want: 0 },
    ]
  }

  function test_cpu_usage_between_samples(data) {
    const usage = System.cpuUsage(System.parseCpuTimes(data.previous), System.parseCpuTimes(data.current))
    verify(usage === data.want, "got " + usage)
  }

  function test_parse_memory() {
    const text = "MemTotal:       15573368 kB\nMemFree:  1 kB\nMemAvailable:    8395340 kB\n"
      + "SwapTotal:      17114436 kB\n"
    compare(System.parseMemory(text), { total: 15573368, available: 8395340 })
    compare(System.parseMemory(""), { total: 0, available: 0 })
  }

  function test_default_interface_data() {
    const header = "Iface\tDestination\tGateway \tFlags\tRefCnt\tUse\tMetric\tMask\t\tMTU\tWindow\tIRTT\n"
    return [
      {
        tag: "lowest metric wins",
        text: header
          + "wlp3s0\t00000000\t0100A8C0\t0003\t0\t0\t600\t00000000\t0\t0\t0\n"
          + "enp5s0\t00000000\t0100A8C0\t0003\t0\t0\t100\t00000000\t0\t0\t0\n"
          + "enp5s0\t0000A8C0\t00000000\t0001\t0\t0\t100\t00FFFFFF\t0\t0\t0\n",
        want: "enp5s0",
      },
      {
        tag: "no default route",
        text: header + "wlp3s0\t0000A8C0\t00000000\t0001\t0\t0\t600\t00FFFFFF\t0\t0\t0\n",
        want: "",
      },
    ]
  }

  function test_default_interface(data) {
    verify(System.defaultInterface(data.text) === data.want)
  }

  function test_upload_rate() {
    const text = "Inter-|   Receive |  Transmit\n face |bytes    packets|bytes\n"
      + "    lo:   32684     360    0    0    0     0          0         0    32684     360    0    0    0     0       0          0\n"
      + "wlp3s0: 1000 10 0 0 0 0 0 0 5000 20 0 0 0 0 0 0\n"
    compare({
      wlan: System.transmittedBytes(text, "wlp3s0"),
      missing: System.transmittedBytes(text, "enp5s0"),
      rate: System.rate(100, 300, 2),
      reset: System.rate(300, 100, 2),
      first: System.rate(undefined, 100, 2),
      instant: System.rate(100, 300, 0),
    }, {
      wlan: 5000,
      missing: null,
      rate: 100,
      reset: 0,
      first: 0,
      instant: 0,
    })
  }

  function test_kill_targets() {
    const unit = "0::/user.slice/user-1001.slice/user@1001.service/app.slice/"
    const text = "   10     1 Sl    5.0  102400 " + unit + "app-niri-ghostty-10.scope .ghostty-wrappe\n"
      + "   11    10 Ss    0.1    4096 " + unit + "app-ghostty-surface-transient-11.scope zsh\n"
      + "   12    11 Sl   95.0  204800 " + unit + "app-ghostty-surface-transient-11.scope .claude-wrapped\n"
      + "   13    11 Sl    1.0   51200 " + unit + "app-ghostty-surface-transient-11.scope gimp\n"
      + "   14     1 Dl    0.0 1024000 " + unit + "app-slack-14.scope slack\n"
      + "   15     1 Z     0.0       0 " + unit + "app-slack-14.scope zombie\n"
      + "   16    11 R   200      1000 " + unit + "app-ghostty-surface-transient-11.scope ps\n"
    const windows = [
      { title: "a", appId: "com.mitchellh.ghostty", pid: 10, focused: true },
      { title: "b", appId: "com.mitchellh.ghostty", pid: 10, focused: false },
      { title: "Chat", appId: "Slack", pid: 14, focused: false },
      { title: "img", appId: "org.gimp.GIMP", pid: 13, focused: false },
    ]
    compare(System.killTargets(windows, System.parseProcesses(text), 2), [
      { label: "ghostty", detail: "2 windows · 5% · 100 MB", hint: "", window: true, pid: 10, unit: "app-niri-ghostty-10.scope" },
      { label: "Slack", detail: "stuck · Chat · 0% · 1000 MB", hint: "stuck", window: true, pid: 14, unit: "app-slack-14.scope" },
      // Started from the shell, so its scope is the shell's.
      { label: "GIMP", detail: "img · 1% · 50 MB", hint: "", window: true, pid: 13, unit: "" },
      { label: "claude", detail: "busy · pid 12 · 95% · 200 MB", hint: "busy", window: false, pid: 12, unit: "" },
      { label: "zsh", detail: "pid 11 · 0% · 4 MB", hint: "", window: false, pid: 11, unit: "" },
    ])
    compare(System.killTargets([], System.parseProcesses(""), 10), [])
  }

  function test_kill_command() {
    compare({
      scope: System.killCommand({ pid: 10, unit: "app-slack-14.scope" }),
      process: System.killCommand({ pid: 12, unit: "" }),
    }, {
      scope: ["systemctl", "--user", "kill", "--signal=KILL", "app-slack-14.scope"],
      process: ["kill", "-KILL", "12"],
    })
  }

  function sample(fields) {
    return Object.assign({ cpu: 10, memory: { total: 100, available: 50 }, temperature: 60, txRate: 0 }, fields)
  }

  function test_conditions_data() {
    return [
      { tag: "idle", sample: sample({}), want: { memory: false, temperature: false, cpu: false, upload: false } },
      {
        tag: "at thresholds",
        sample: sample({ cpu: 80, memory: { total: 100, available: 9 }, temperature: 90, txRate: 2000000 }),
        want: { memory: true, temperature: true, cpu: true, upload: true },
      },
      {
        tag: "unread sensors",
        sample: sample({ memory: { total: 0, available: 0 }, temperature: NaN }),
        want: { memory: false, temperature: false, cpu: false, upload: false },
      },
    ]
  }

  function test_conditions(data) {
    compare(System.conditions(data.sample), data.want)
  }

  function test_alerts_need_a_sustained_condition() {
    const kinds = alerts => alerts.map(alert => alert.kind)
    const busy = System.conditions(sample({ cpu: 95 }))
    const starts = System.since({}, busy, 1000)
    const held = System.since(starts, busy, 31000)
    const cleared = System.since(held, System.conditions(sample({})), 41000)
    const all = { memory: 1, temperature: 1, cpu: 1, upload: 1 }
    compare({
      starts: starts,
      early: kinds(System.sustained(held, 30999)),
      held: kinds(System.sustained(held, 31000)),
      cleared: kinds(System.sustained(cleared, 41000)),
      ordered: kinds(System.sustained(all, 30001)),
    }, {
      starts: { memory: 0, temperature: 0, cpu: 1000, upload: 0 },
      early: [],
      held: ["cpu"],
      cleared: [],
      ordered: ["memory", "temperature", "cpu", "upload"],
    })
  }
}
