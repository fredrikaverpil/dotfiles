{ lib, pkgs, ... }:
# The minimal tray plugin: an app with its own StatusNotifierItem and menu,
# which the shell's tray shows. It needs no shell code.
let
  # Start with the session; otherwise start it from the launcher's Apps.
  autostart = true;

  hello-tray = pkgs.buildGo127Module {
    pname = "hello-tray";
    version = "0.1.0";
    src = ./.;
    vendorHash = "sha256-4dUCx2EuKoELZOUXzX6lSkmzWfScv83EuAtf5qFBIAc=";
    meta.mainProgram = "hello-tray";
  };
in
{
  # Starts the unit, so it runs once however it was started.
  environment.systemPackages = [
    (pkgs.makeDesktopItem {
      name = "hello-tray";
      desktopName = "Hello tray";
      exec = "systemctl --user start hello-tray.service";
    })
  ];

  systemd.user.services.hello-tray = {
    description = "Hello tray plugin";
    partOf = [ "graphical-session.target" ];
    # The shell hosts the StatusNotifierWatcher it registers with.
    after = [ "quickshell.service" ];
    wantedBy = lib.optional autostart "wayland-session@niri.target";
    serviceConfig = {
      ExecStart = lib.getExe hello-tray;
      # Quit in its menu exits 0 and leaves it stopped.
      Restart = "on-failure";
      Slice = "app.slice";
    };
  };
}
