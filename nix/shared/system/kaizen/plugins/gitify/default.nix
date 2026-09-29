{ lib, pkgs, ... }:
let
  gitify = pkgs.withGnomeLibsecret pkgs.gitify;
in
{
  systemd.user.services.gitify = {
    description = "Gitify";
    partOf = [ "graphical-session.target" ];
    after = [ "quickshell.service" ];
    wantedBy = [ "wayland-session@niri.target" ];
    serviceConfig = {
      ExecStart = lib.getExe' gitify "gitify";
      Restart = "on-failure";
      Slice = "app.slice";
    };
  };
}
