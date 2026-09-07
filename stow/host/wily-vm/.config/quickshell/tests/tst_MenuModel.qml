import QtQuick
import QtTest
import "../plugins/menu/MenuModel.js" as Menu

TestCase {
  name: "MenuModel"

  readonly property var items: ({
    apps: { label: "Apps", provider: "apps" },
    learn: { label: "Learn" },
    "learn.keys": { label: "Keys", provider: "binds" },
    style: { label: "Style" },
    "style.dark": { label: "Dark" },
    "style.disabled": { label: "Disabled", enabled: false },
  })

  function test_bind_parser_accepts_the_tsv_contract_written_by_both_compositors() {
    compare(Menu.parseBinds("SUPER + K\tKeybindings\nMod+K\tKeybindings\n"), [
      { chord: "SUPER + K", label: "Keybindings", enabled: true },
      { chord: "Mod+K", label: "Keybindings", enabled: true },
    ])
    compare(Menu.parseBinds("\n"), [])
  }

  function test_hierarchy_paths_and_rows_describe_menu_descendants() {
    compare(Menu.childrenOf(items, "root"), ["apps", "learn", "style"])
    compare(Menu.childrenOf(items, "learn"), ["learn.keys"])
    compare(Menu.descendantsOf(items, "root"), ["apps", "learn", "learn.keys", "style", "style.dark", "style.disabled"])
    compare(Menu.pathFrom(items, "learn.keys", "root"), "Learn")
    compare(Menu.rowFor(items, "learn", "root").submenu, true)
    compare(Menu.rowFor(items, "style.disabled", "root").enabled, false)
    compare(Menu.parentLevel("style.dark"), "style")
    compare(Menu.parentLevel("style"), "root")
  }

  function test_row_selection_filters_providers_and_sorts_direct_descendants_first() {
    const apps = detail => [{ label: "Alacritty", detail, enabled: true, entry: {} }]
    const trays = () => [{ label: "Network", enabled: true }]
    const binds = [{ chord: "SUPER + K", label: "Keybindings", enabled: true }]

    compare(Menu.rowsFor(items, "learn.keys", "k", binds, trays, apps), binds)
    compare(Menu.rowsFor(items, "apps", "", binds, trays, apps), apps(""))
    compare(Menu.rowsFor(items, "root", "a", binds, trays, apps).map(row => row.label), ["Apps", "Learn", "Dark", "Alacritty"])
    compare(Menu.rowsFor(items, "root", "", binds, trays, apps).map(row => row.id), ["apps", "learn", "style"])
  }

  function test_keyboard_movement_wraps_and_skips_disabled_rows() {
    const rows = [{ enabled: true }, { enabled: false }, { enabled: true }]
    compare(Menu.selectFirstEnabled([{ enabled: false }, { enabled: true }]), 1)
    compare(Menu.selectFirstEnabled([]), 0)
    compare(Menu.moveIndex(rows, 0, 1), 2)
    compare(Menu.moveIndex(rows, 2, 1), 0)
    compare(Menu.moveIndex(rows, 0, -1), 2)
    compare(Menu.moveIndex(rows, 0, 10), 0)
  }
}
