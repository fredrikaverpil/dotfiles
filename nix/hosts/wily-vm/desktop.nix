{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  # UTM's virgl lacks the desktop GL version Ghostty requires; keep software GL scoped to it.
  ghostty-softgl = pkgs.symlinkJoin {
    name = "ghostty-softgl";
    paths = [ pkgs.ghostty ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/ghostty --set LIBGL_ALWAYS_SOFTWARE 1
    '';
  };

  sleep-lock-monitor = pkgs.writeShellApplication {
    name = "wily-sleep-lock-monitor";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.dbus
      pkgs.gnugrep
      pkgs.quickshell
      pkgs.systemd
    ];
    text = ''
      lock_and_wait() {
        qs ipc call lock lock >/dev/null || return 1

        for _ in $(seq 1 30); do
          if qs ipc call lock status 2>/dev/null | grep -q '"secure":true'; then
            echo "wily: session lock is secure, releasing the suspend delay"
            return 0
          fi
          sleep 0.1
        done

        return 1
      }

      monitor_sleep() {
        while IFS= read -r line; do
          if [[ $line == *"boolean true"* ]]; then
            lock_and_wait || echo "wily: session lock was not secure before suspend" >&2
            return
          fi
        done < <(dbus-monitor --system \
          "type='signal',sender='org.freedesktop.login1',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'")
      }

      if [[ ''${1:-} == "--monitor" ]]; then
        monitor_sleep
      else
        exec systemd-inhibit \
          --what=sleep \
          --mode=delay \
          --who=wily \
          --why="Secure the Quickshell lock screen before suspend" \
          "$0" --monitor
      fi
    '';
  };
  cliamp-desktop = pkgs.makeDesktopItem {
    name = "cliamp";
    desktopName = "cliamp";
    comment = "Terminal Winamp";
    exec = "ghostty -e cliamp";
    terminal = false;
    categories = [
      "Audio"
      "Player"
    ];
  };
in
{
  imports = [ inputs.dankcalendar.nixosModules.default ];

  programs.dank-calendar.enable = true;
  # OAuth tokens stay in the user's keyring, unlocked by the console login PAM stack.
  services.gnome.gnome-keyring.enable = true;

  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };

  # niri has no portal default; the GTK settings portal supplies the shell's theme setting.
  xdg.portal.config.niri.default = [ "gtk" ];

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  security.rtkit.enable = true;

  # GTK3 needs the portal to follow the dconf theme; Qt uses the GTK platform theme.
  environment.sessionVariables = {
    HYPRCURSOR_THEME = "macOS-hypr";
    HYPRCURSOR_SIZE = "24";
    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORMTHEME = "gtk3";
    GTK_USE_PORTAL = "1";
  };

  security.polkit.enable = true;

  # polkit.enable does not install the setuid pkexec wrapper.
  security.polkit.enablePkexecWrapper = true;

  # The custom PAM service bypasses an aarch64 NixOS PAM-module evaluation bug.
  environment.etc."pam.d/wily-lock".text = ''
    auth include login
  '';

  systemd.user.services.quickshell = {
    description = "Quickshell desktop shell";
    partOf = [ "graphical-session.target" ];
    # Never order after graphical-session.target: that creates a systemd cycle.
    # waitenv closes niri's readiness-before-WAYLAND_DISPLAY race.
    after = [
      "wayland-wm@hyprland.desktop.service"
      "wayland-wm@niri.service"
      "wayland-session-waitenv.service"
    ];
    # Bind to compositor-specific sessions so another desktop cannot start a second shell.
    wantedBy = [
      "wayland-session@hyprland.desktop.target"
      "wayland-session@niri.target"
    ];
    # NixOS pins a sparse user-unit PATH; inherit UWSM's session PATH for app launchers.
    environment.PATH = lib.mkForce null;
    # qtimageformats supplies Quickshell's WebP decoder.
    environment.QT_PLUGIN_PATH = "${pkgs.qt6.qtimageformats}/lib/qt-6/plugins";
    serviceConfig = {
      ExecStart = "${pkgs.quickshell}/bin/quickshell";
      Restart = "on-failure";
    };
  };

  # Keep the upstream systemd option off: its unit orders after graphical-session.target.
  # Sync and reminders outlive the calendar window and run independently of our shell.
  systemd.user.services.dcal = {
    description = "DankCalendar sync and reminders";
    partOf = [ "graphical-session.target" ];
    after = [
      "dbus.socket"
      "quickshell.service"
      "wayland-wm@hyprland.desktop.service"
      "wayland-wm@niri.service"
      "wayland-session-waitenv.service"
    ];
    wantedBy = [
      "wayland-session@hyprland.desktop.target"
      "wayland-session@niri.target"
    ];
    # NixOS pins a sparse user-unit PATH; inherit UWSM's session PATH so dcal can
    # launch its Quickshell UI and open OAuth URLs with the session's tools.
    environment.PATH = lib.mkForce null;
    serviceConfig = {
      # OpenSession prevents the weak local fallback; the collection probe catches broken first-use initialization.
      ExecStartPre = [
        "${pkgs.systemd}/bin/busctl --user --timeout=15 --quiet call org.freedesktop.secrets /org/freedesktop/secrets org.freedesktop.Secret.Service OpenSession sv plain s \"\""
        "${pkgs.systemd}/bin/busctl --user --timeout=15 --quiet get-property org.freedesktop.secrets /org/freedesktop/secrets/collection/login org.freedesktop.Secret.Collection Locked"
      ];
      ExecStart = "${lib.getExe config.programs.dank-calendar.package} run --session --hidden";
      Restart = "on-failure";
      RestartSec = "2s";
      Slice = "app.slice";
      UMask = "0077";
    };
  };

  systemd.user.services.wily-sleep-lock = {
    description = "Lock Quickshell before suspend";
    partOf = [ "graphical-session.target" ];
    # Match Quickshell's ordering: waitenv is required for niri, and graphical-session.target cycles.
    after = [
      "dbus.socket"
      "wayland-wm@hyprland.desktop.service"
      "wayland-wm@niri.service"
      "wayland-session-waitenv.service"
    ];
    requires = [ "dbus.socket" ];
    wantedBy = [
      "wayland-session@hyprland.desktop.target"
      "wayland-session@niri.target"
    ];
    serviceConfig = {
      ExecStart = "${sleep-lock-monitor}/bin/wily-sleep-lock-monitor";
      Restart = "always";
      RestartSec = "2s";
    };
  };

  # curl-cffi's aarch64 TLS tests fail, though the package itself works.
  nixpkgs.overlays = [
    (final: prev: {
      python3Packages = prev.python3Packages.overrideScope (
        pyFinal: pyPrev: {
          curl-cffi = pyPrev.curl-cffi.overridePythonAttrs { doCheck = false; };
        }
      );
    })
  ];

  host.extraSystemPackages = with pkgs; [
    quickshell
    niri
    wl-gammarelay-rs
    libnotify
    sound-theme-freedesktop
    kdePackages.dolphin
    kdePackages.kconfig
    ghostty-softgl
    gnome-themes-extra
    iproute2
    iputils

    (chromium.override { commandLineArgs = "--no-first-run"; })
    cliamp
    cliamp-desktop
    firefox
    grim
    wl-clipboard
    wtype
    signal-desktop
    zed-editor
  ];
}
