import { createRequire } from "node:module"
import { assertEquals } from "jsr:@std/assert"

const Menu = createRequire(import.meta.url)("../plugins/menu/MenuModel.js")

const items = {
  apps: { label: "Apps", provider: "apps" },
  learn: { label: "Learn" },
  "learn.keys": { label: "Keys", provider: "binds" },
  style: { label: "Style" },
  "style.dark": { label: "Dark" },
  "style.disabled": { label: "Disabled", enabled: false },
}

Deno.test("bind parser accepts the TSV contract written by both compositors", () => {
  assertEquals(Menu.parseBinds("SUPER + K\tKeybindings\nMod+K\tKeybindings\n"), [
    { chord: "SUPER + K", label: "Keybindings", enabled: true },
    { chord: "Mod+K", label: "Keybindings", enabled: true },
  ])
  assertEquals(Menu.parseBinds("\n"), [])
})

Deno.test("hierarchy paths and rows describe menu descendants", () => {
  assertEquals(Menu.childrenOf(items, "root"), ["apps", "learn", "style"])
  assertEquals(Menu.childrenOf(items, "learn"), ["learn.keys"])
  assertEquals(Menu.descendantsOf(items, "root"), ["apps", "learn", "learn.keys", "style", "style.dark", "style.disabled"])
  assertEquals(Menu.pathFrom(items, "learn.keys", "root"), "Learn")
  assertEquals(Menu.rowFor(items, "learn", "root").submenu, true)
  assertEquals(Menu.rowFor(items, "style.disabled", "root").enabled, false)
  assertEquals(Menu.parentLevel("style.dark"), "style")
  assertEquals(Menu.parentLevel("style"), "root")
})

Deno.test("row selection filters providers and sorts direct descendants first", () => {
  const apps = detail => [{ label: "Alacritty", detail, enabled: true, entry: {} }]
  const trays = () => [{ label: "Network", enabled: true }]
  const binds = [{ chord: "SUPER + K", label: "Keybindings", enabled: true }]

  assertEquals(Menu.rowsFor(items, "learn.keys", "k", binds, trays, apps), binds)
  assertEquals(Menu.rowsFor(items, "apps", "", binds, trays, apps), apps(""))
  assertEquals(Menu.rowsFor(items, "root", "a", binds, trays, apps).map(row => row.label), ["Apps", "Learn", "Dark", "Alacritty"])
  assertEquals(Menu.rowsFor(items, "root", "", binds, trays, apps).map(row => row.id), ["apps", "learn", "style"])
})

Deno.test("keyboard movement wraps and skips disabled rows", () => {
  const rows = [{ enabled: true }, { enabled: false }, { enabled: true }]
  assertEquals(Menu.selectFirstEnabled([{ enabled: false }, { enabled: true }]), 1)
  assertEquals(Menu.selectFirstEnabled([]), 0)
  assertEquals(Menu.moveIndex(rows, 0, 1), 2)
  assertEquals(Menu.moveIndex(rows, 2, 1), 0)
  assertEquals(Menu.moveIndex(rows, 0, -1), 2)
  assertEquals(Menu.moveIndex(rows, 0, 10), 0)
})
