import QtQuick
import QtTest
import "../plugins/polkit/PolkitModel.js" as Polkit

TestCase {
  name: "PolkitModel"

  function test_polkit_authorization_labels_retain_unknown_messages() {
    compare(Polkit.authorizationLabel("Authentication is needed to run `nixos-rebuild` as super user"), "Authorize running 'nixos-rebuild'")
    compare(Polkit.authorizationLabel("Authentication is required to run 'systemctl reboot' as root"), "Authorize running 'systemctl reboot'")
    compare(Polkit.authorizationLabel("A localized message"), "A localized message")
    compare(Polkit.authorizationLabel(null), "")
  }
}
