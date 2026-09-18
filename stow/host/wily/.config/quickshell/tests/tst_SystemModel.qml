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
