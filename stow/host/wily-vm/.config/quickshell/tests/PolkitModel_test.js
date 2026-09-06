import { createRequire } from "node:module"
import { assertEquals } from "jsr:@std/assert"

const Polkit = createRequire(import.meta.url)("../plugins/polkit/PolkitModel.js")

Deno.test("polkit authorization labels retain unknown messages", () => {
  assertEquals(Polkit.authorizationLabel("Authentication is needed to run `nixos-rebuild` as super user"), "Authorize running 'nixos-rebuild'")
  assertEquals(Polkit.authorizationLabel("Authentication is required to run 'systemctl reboot' as root"), "Authorize running 'systemctl reboot'")
  assertEquals(Polkit.authorizationLabel("A localized message"), "A localized message")
  assertEquals(Polkit.authorizationLabel(null), "")
})
