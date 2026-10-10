{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
# The calendar shell plugin and dcal, the daemon it queries.
{
  imports = [ inputs.dankcalendar.homeModules.default ];

  # Read from the checkout, so `qs ipc call shell reload` applies edits.
  kaizen.plugins = [
    "${config.home.homeDirectory}/.dotfiles/nix/shared/system/kaizen/plugins/calendar"
  ];

  # OAuth tokens stay in gnome-keyring (from programs.niri), unlocked by the login PAM stack.
  # Calendar credentials and feed URLs are private user state, never Nix/Stow values.
  programs.dank-calendar.enable = true;

  # Keep the upstream systemd option off: its unit orders after graphical-session.target.
  # Sync and reminders outlive the calendar window and run independently of our shell.
  # The unit inherits UWSM's session PATH, so dcal can launch its Quickshell UI and
  # open OAuth URLs with the session's tools.
  systemd.user.services.kaizen-dcal = {
    Unit = {
      Description = "DankCalendar sync and reminders";
      PartOf = [ "graphical-session.target" ];
      After = [
        "dbus.socket"
        "kaizen-shell.service"
        "wayland-wm@niri.service"
        "wayland-session-waitenv.service"
      ];
      # Retry indefinitely, e.g. while the keyring is not yet unlocked.
      StartLimitIntervalSec = 0;
    };
    Service = {
      # dcal must see Secret Service before starting: its local keyring fallback uses a fixed password.
      # OpenSession prevents that fallback; the collection probe catches first-use keyring
      # initialization that advertises `login` without exporting it. Manually launched
      # instances bypass both probes.
      ExecStartPre = [
        "${pkgs.systemd}/bin/busctl --user --timeout=15 --quiet call org.freedesktop.secrets /org/freedesktop/secrets org.freedesktop.Secret.Service OpenSession sv plain s \"\""
        "${pkgs.systemd}/bin/busctl --user --timeout=15 --quiet get-property org.freedesktop.secrets /org/freedesktop/secrets/collection/login org.freedesktop.Secret.Collection Locked"
      ];
      ExecStart = "${lib.getExe config.programs.dank-calendar.package} run --session --hidden";
      # The UI's Quit makes the daemon SIGTERM itself and exit 0.
      Restart = "always";
      RestartSec = "2s";
      Slice = "app.slice";
      UMask = "0077";
    };
    Install.WantedBy = [ "wayland-session@niri.target" ];
  };
}
