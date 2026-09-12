import QtQuick
import QtTest
import "../plugins/services/system/SystemModel.js" as System

TestCase {
  name: "SystemModel"

  function test_cpu_usage_between_samples_data() {
    return [
      {
        tag: "total and cores",
        previous: "cpu  10 0 10 70 10 0 0 0 0 0\ncpu0 5 0 5 35 5 0 0 0 0 0\nintr 1 2\n",
        current: "cpu  60 0 10 120 10 0 0 0 0 0\ncpu0 55 0 5 35 5 0 0 0 0 0\nintr 3 4\n",
        want: [50, 100],
      },
      { tag: "no previous sample", previous: "", current: "cpu  1 0 0 1 0 0 0 0 0 0\n", want: [] },
      {
        tag: "core count changed",
        previous: "cpu  1 0 0 1 0 0 0 0 0 0\n",
        current: "cpu  2 0 0 2 0 0 0 0 0 0\ncpu0 2 0 0 2 0 0 0 0 0 0\n",
        want: [],
      },
      { tag: "no time passed", previous: "cpu  1 0 0 1 0 0 0 0 0 0\n", current: "cpu  1 0 0 1 0 0 0 0 0 0\n", want: [0] },
    ]
  }

  function test_cpu_usage_between_samples(data) {
    const previous = data.previous === "" ? null : System.parseCpuTimes(data.previous)
    compare(System.cpuUsage(previous, System.parseCpuTimes(data.current)), data.want)
  }

  function test_parse_memory() {
    const text = "MemTotal:       15573368 kB\nMemFree:  1 kB\nMemAvailable:    8395340 kB\n"
      + "SwapTotal:      17114436 kB\nSwapFree:       17000000 kB\n"
    compare(System.parseMemory(text), { total: 15573368, available: 8395340, swapTotal: 17114436, swapFree: 17000000 })
    compare(System.parseMemory(""), { total: 0, available: 0, swapTotal: 0, swapFree: 0 })
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

  function test_interface_rates() {
    const text = "Inter-|   Receive |  Transmit\n face |bytes    packets|bytes\n"
      + "    lo:   32684     360    0    0    0     0          0         0    32684     360    0    0    0     0       0          0\n"
      + "wlp3s0: 1000 10 0 0 0 0 0 0 5000 20 0 0 0 0 0 0\n"
    compare({
      wlan: System.interfaceBytes(text, "wlp3s0"),
      missing: System.interfaceBytes(text, "enp5s0"),
      rate: System.rate(100, 300, 2),
      reset: System.rate(300, 100, 2),
      first: System.rate(undefined, 100, 2),
      instant: System.rate(100, 300, 0),
    }, {
      wlan: { rx: 1000, tx: 5000 },
      missing: null,
      rate: 100,
      reset: 0,
      first: 0,
      instant: 0,
    })
  }

  function test_parse_top_uses_last_iteration() {
    const text = "top - 12:00:00 up 1 day\n"
      + "    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND\n"
      + "      1 root      20   0       0      0      0 S  99.0   0.0   0:00.00 stale\n"
      + "\n"
      + "top - 12:00:01 up 1 day\n"
      + "    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND\n"
      + "  19781 fredrik   25   5 5601352 437288 119112 S  17.0   2.8   2:28.14 .claude-wrapped\n"
      + "   2345 fredrik   20   0 3767252 317336 111564 S   7,6   2.0   3:13.07 Web Content\n"
      + "   3329 fredrik   20   0   12.1g 763196 302592 S   3.8   4.9   7:34.00 .zen-beta-wrapp\n"
    compare(System.parseTop(text, 2), [
      { pid: 19781, cpu: 17, memory: 2.8, name: "claude" },
      { pid: 2345, cpu: 7.6, memory: 2, name: "Web Content" },
    ])
    compare(System.parseTop("", 5), [])
  }

  function test_formatting() {
    compare({
      zero: System.formatRate(0),
      bytes: System.formatRate(999),
      kilo: System.formatRate(1500),
      wholeKilo: System.formatRate(25000),
      mega: System.formatRate(2500000),
      usage: System.formatUsage(7549747, 15573368),
    }, {
      zero: "0 B/s",
      bytes: "999 B/s",
      kilo: "1.5 kB/s",
      wholeKilo: "25 kB/s",
      mega: "2.5 MB/s",
      usage: "7.2 / 14.9 GiB",
    })
  }
}
