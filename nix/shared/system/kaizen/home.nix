{ pkgs, ... }:
let
  # The shell's emoji data, found as share/kaizen/emoji.json in the XDG data dirs.
  emoji =
    pkgs.runCommand "kaizen-emoji"
      {
        nativeBuildInputs = [ pkgs.jq ];
        names = "${pkgs.unicode-emoji}/share/unicode/emoji/emoji-test.txt";
        shortcodes = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/iamcal/emoji-data/v16.0.0/emoji.json";
          hash = "sha256-HWAuZb6Idyv4zDaM4WuFXXGe7duv4SjUcbgCA/SU0p8=";
        };
      }
      ''
        mkdir -p $out/share/kaizen
        bash ${../../../../stow/kaizen/.local/bin/kaizen-emoji} "$names" "$shortcodes" > $out/share/kaizen/emoji.json
      '';

  sleep-lock-monitor = pkgs.writeShellApplication {
    name = "kaizen-sleep-lock-monitor";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.dbus
      pkgs.gnugrep
      pkgs.quickshell
      pkgs.systemd
    ];
    text = builtins.readFile ./scripts/kaizen-sleep-lock-monitor.sh;
  };
  # Focuses the most recently focused niri window whose app id matches, or runs
  # the command when none does. niri's binds call it.
  kaizen-focus = pkgs.writeShellApplication {
    name = "kaizen-focus";
    runtimeInputs = [
      pkgs.jq
      pkgs.niri
    ];
    text = builtins.readFile ./scripts/kaizen-focus.sh;
  };
  # Lists the shell's IPC functions, all targets or one, sorted by target.
  kaizen-ipc = pkgs.writeShellApplication {
    name = "kaizen-ipc";
    runtimeInputs = [
      pkgs.gawk
      pkgs.quickshell
    ];
    text = builtins.readFile ./scripts/kaizen-ipc.sh;
  };
  # Lists warnings and errors from the kaizen-* user units, this boot by default.
  kaizen-log = pkgs.writeShellApplication {
    name = "kaizen-log";
    runtimeInputs = [
      pkgs.jq
      pkgs.systemd
    ];
    text = builtins.readFile ./scripts/kaizen-log.sh;
  };

  # bluetui registers its own pairing agent; the shell has none.
  bluetui-desktop = pkgs.makeDesktopItem {
    name = "bluetui";
    desktopName = "bluetui";
    comment = "Bluetooth pairing";
    exec = "bluetui";
    terminal = true;
    categories = [
      "Settings"
      "HardwareSettings"
    ];
  };
in
# The user half of the kaizen session: the shell's user units and the
# pre-suspend lock, and the packages and data the shell and its binds use. A
# home-manager module, so it also runs on a distro other than NixOS; session.nix
# holds the system half and adds this module to every home-manager user. Compositor config, QML and notification rules live in
# stow/kaizen/.
{
  config = {
    # A switch never restarts the shell or the lock monitor, so a rebuild cannot
    # restart Quickshell under a session lock; restart them by hand, unlocked.
    systemd.user.services.kaizen-shell = {
      Unit = {
        Description = "Quickshell desktop shell";
        PartOf = [ "graphical-session.target" ];
        # Never order after graphical-session.target: that creates a systemd cycle.
        # waitenv closes niri's readiness-before-WAYLAND_DISPLAY race.
        After = [
          "wayland-wm@niri.service"
          "wayland-session-waitenv.service"
        ];
        X-SwitchMethod = "keep-old";
      };
      Service = {
        # The unit inherits UWSM's session PATH, which launcher entries and uwsm-app need.
        Environment = [
          # qtimageformats supplies Quickshell's WebP decoder.
          "QT_PLUGIN_PATH=${pkgs.qt6.qtimageformats}/lib/qt-6/plugins"
        ];
        ExecStart = "${pkgs.quickshell}/bin/quickshell";
        Restart = "on-failure";
        # Creates ~/.local/state/kaizen-shell before ExecStart: for user units
        # StateDirectory resolves under $XDG_STATE_HOME.
        StateDirectory = "kaizen-shell";
      };
      # Bind to the niri session so another desktop cannot start a second shell.
      Install.WantedBy = [ "wayland-session@niri.target" ];
    };

    # Holds XDG autostart apps (UWSM orders them after this target) until the tray's
    # StatusNotifierWatcher is up; Electron apps look for it once and never retry.
    # The shell registers it once its config loads, which waits for xdg-desktop-portal,
    # itself ordered after graphical-session.target: waiting in kaizen-shell.service would deadlock.
    systemd.user.services.kaizen-tray-ready = {
      Unit = {
        Description = "Wait for the Quickshell tray";
        Before = [ "wayland-session-xdg-autostart@niri.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.bash}/bin/bash -c 'until ${pkgs.systemd}/bin/busctl --user status org.kde.StatusNotifierWatcher >/dev/null 2>&1; do ${pkgs.coreutils}/bin/sleep 0.2; done'";
        # A tray that never comes up delays autostart apps, never blocks them.
        TimeoutStartSec = 10;
      };
      Install.WantedBy = [ "wayland-session-xdg-autostart@niri.target" ];
    };

    # Lid close and the power key suspend via logind; this delay inhibitor locks
    # the shell first and releases once the lock reports secure.
    systemd.user.services.kaizen-sleep-lock = {
      Unit = {
        Description = "Lock Quickshell before suspend";
        PartOf = [ "graphical-session.target" ];
        # Match Quickshell's ordering: waitenv is required for niri, and graphical-session.target cycles.
        After = [
          "dbus.socket"
          "wayland-wm@niri.service"
          "wayland-session-waitenv.service"
        ];
        Requires = [ "dbus.socket" ];
        X-SwitchMethod = "keep-old";
      };
      Service = {
        ExecStart = "${sleep-lock-monitor}/bin/kaizen-sleep-lock-monitor";
        Restart = "always";
        RestartSec = "2s";
      };
      Install.WantedBy = [ "wayland-session@niri.target" ];
    };

    home.packages = with pkgs; [
      quickshell
      # niri's terminal binds and xdg-terminal-exec open it.
      ghostty
      # Nightlight: drives zwlr_gamma_control_v1, so it is compositor-agnostic.
      wl-gammarelay-rs
      libnotify
      sound-theme-freedesktop
      kdePackages.kconfig
      gnome-themes-extra
      # Cursor theme for niri, GTK and Qt; without one niri draws a fixed 64px fallback.
      bibata-cursors
      iproute2
      iputils
      bluetui
      bluetui-desktop
      emoji
      grim
      imagemagick # Wallpaper thumbnails.
      jq # The clipboard watcher's JSON encoding.
      kaizen-focus
      kaizen-ipc
      kaizen-log
      mpv
      # nm-connection-editor edits wired, static-IP and other connection settings;
      # the network panel launches it. nm-applet runs via XDG autostart for its tray menu.
      networkmanagerapplet
      # Annotates screenshots from the notification's Edit action.
      satty
      wl-clipboard
      # niri cannot mirror outputs; the mirror service runs it fullscreen on the target.
      wl-mirror
    ];
  };
}
