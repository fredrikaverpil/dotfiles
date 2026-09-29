{ lib, pkgs, ... }:
# GitHub notifications tray app (https://github.com/gitify-app/gitify), same
# minimal shape as hello-tray: its own StatusNotifierItem and menu, no
# Plugin.qml needed. Electron, so it needs the gnome-libsecret wrapper to
# persist its GitHub token (see desktop.nix's withGnomeLibsecret).
let
  gitify = pkgs.withGnomeLibsecret pkgs.gitify;
in
{
  systemd.user.services.gitify = {
    description = "Gitify";
    partOf = [ "graphical-session.target" ];
    # The shell hosts the StatusNotifierWatcher it registers with.
    after = [ "quickshell.service" ];
    wantedBy = [ "wayland-session@niri.target" ];
    serviceConfig = {
      # gitify has no meta.mainProgram; getExe' names the binary explicitly.
      ExecStart = lib.getExe' gitify "gitify";
      Restart = "on-failure";
      Slice = "app.slice";
    };
  };
}
