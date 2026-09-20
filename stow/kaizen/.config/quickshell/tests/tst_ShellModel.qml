import QtQuick
import QtTest
import "../ShellModel.js" as Shell

TestCase {
  name: "ShellModel"

  readonly property var dark: ({ bg: "#1C1917", fg: "#B4BDC3" })
  readonly property var light: ({ bg: "#F0EDEC", fg: "#2C363C" })

  function test_kde_palette_writes_encode_colours_without_qt_runtime_helpers() {
    compare(Shell.rgb("#1C1917"), "28,25,23")
    compare(Shell.rgb("invalid"), "")
    compare(Shell.kdeglobalsWrite(true, dark, light), "kwriteconfig6 --notify --file kdeglobals --group 'Colors:View' --key BackgroundNormal '28,25,23'; kwriteconfig6 --notify --file kdeglobals --group 'Colors:View' --key ForegroundNormal '180,189,195'; ")
    compare(Shell.kdeglobalsWrite(false, dark, light), "kwriteconfig6 --notify --file kdeglobals --group 'Colors:View' --key BackgroundNormal '240,237,236'; kwriteconfig6 --notify --file kdeglobals --group 'Colors:View' --key ForegroundNormal '44,54,60'; ")
  }

  function test_text_scale_parsing_distinguishes_invalid_values_from_valid_limits() {
    compare(Shell.textScale("1.25"), 1.25)
    compare(Shell.textScale(0.7), null)
    compare(Shell.textScale(1.6), null)
    compare(Shell.textScale(null), null)
    compare(Shell.observedTextScale(" 1.1\n"), 1.1)
    compare(Shell.observedTextScale("invalid"), null)
    compare(Shell.observedTextScale(0), null)
  }
}
