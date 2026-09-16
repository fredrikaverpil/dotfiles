# iPhone bridge: clipboard and file transfer over Wi-Fi, messages, contacts and
# notification mirroring over Bluetooth. Both transports are optional and
# independent; see docs/BLUETOOTH.md and docs/HEADLESS.md upstream.
{
  config,
  inputs,
  pkgs,
  ...
}:
{
  imports = [ inputs.tether.nixosModules.tether ];

  programs.tether = {
    enable = true;
    # The module's own default calls upstream's package.nix without the
    # npmConfigHook its flake passes, so name the flake's package instead.
    package = inputs.tether.packages.${pkgs.stdenv.hostPlatform.system}.tether;
    # Publishes the daemon over mDNS so the iOS app finds it; 5134/tcp is the
    # mTLS peer listener. Avahi itself is already on for driverless printing.
    wifi.enable = true;
    wifi.openFirewall = true;
    # Sets the adapter's Class of Device to A/V Hands-Free on every
    # bluetooth.service start and turns on BlueZ's experimental bearer API:
    # iOS offers the message and contact permissions only to that class, and
    # ANCS notification mirroring needs the LE bearer present before pairing.
    bluetooth.enable = true;
  };

  # The package carries a tetherd user unit but the module does not activate it.
  # Without it the daemon lives only as long as a client keeps it alive, so
  # notification mirroring would stop whenever the GTK app is closed.
  systemd.packages = [ config.programs.tether.package ];
  systemd.user.services.tetherd.wantedBy = [ "default.target" ];

  # The browser and mail extensions (OTP autofill) are left out: the module
  # wires Firefox through programs.firefox, which this host does not use.
}
