{ lib, pkgs, ... }:
let
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
  # bluetui registers its own pairing agent; the shell has none.
  bluetui-desktop = pkgs.makeDesktopItem {
    name = "bluetui";
    desktopName = "bluetui";
    comment = "Bluetooth pairing";
    exec = "ghostty -e bluetui";
    terminal = false;
    categories = [
      "Settings"
      "HardwareSettings"
    ];
  };
in
{
  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };

  # Also enables 32-bit graphics; Proton versions are picked in Steam.
  programs.steam.enable = true;

  # niri has no portal default; the GTK settings portal supplies the shell's theme setting.
  xdg.portal.config.niri.default = [ "gtk" ];

  # KService builds Dolphin's application list from an applications menu, which only Plasma ships.
  # Plasma's own menu would pull in plasma-workspace; KService only needs every app listed.
  environment.etc."xdg/menus/applications.menu".text = ''
    <!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
      "http://www.freedesktop.org/standards/menu-spec/1.0/menu.dtd">
    <Menu>
      <Name>Applications</Name>
      <DefaultAppDirs/>
      <DefaultDirectoryDirs/>
      <Include><All/></Include>
    </Menu>
  '';

  # The setcap wrapper lets monitor capture skip the portal dialog.
  programs.gpu-screen-recorder.enable = true;

  xdg.mime.defaultApplications =
    lib.genAttrs [
      "image/png"
      "image/jpeg"
      "image/gif"
      "image/webp"
      "image/bmp"
      "image/tiff"
    ] (_: "imv.desktop")
    // lib.genAttrs [
      "video/mp4"
      "video/webm"
      "video/x-matroska"
      "video/quicktime"
      "video/x-msvideo"
    ] (_: "mpv.desktop");

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  security.rtkit.enable = true;

  # The shell's battery service reads UPower and power-profiles-daemon over D-Bus.
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

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

  # Dedicated PAM service for the Quickshell lock screen.
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

  host.extraSystemPackages = with pkgs; [
    quickshell
    niri
    # niri spawns it on demand and exports DISPLAY for X11 apps.
    # 0.8.2 closes Steam menus instantly (Supreeeme/xwayland-satellite#468, fixed
    # on main by #494); drop this pin once a newer release lands in nixpkgs.
    (xwayland-satellite.overrideAttrs (
      finalAttrs: _: {
        version = "0.8.1";
        src = fetchFromGitHub {
          owner = "Supreeeme";
          repo = "xwayland-satellite";
          tag = "v${finalAttrs.version}";
          hash = "sha256-BUE41HjLIGPjq3U8VXPjf8asH8GaMI7FYdgrIHKFMXA=";
        };
        cargoDeps = rustPlatform.fetchCargoVendor {
          inherit (finalAttrs) src;
          hash = "sha256-16L6gsvze+m7XCJlOA1lsPNELE3D364ef2FTdkh0rVY=";
        };
      }
    ))
    wl-gammarelay-rs
    libnotify
    sound-theme-freedesktop
    kdePackages.dolphin
    # Dolphin thumbnails for images and videos.
    kdePackages.kio-extras
    kdePackages.ffmpegthumbs
    kdePackages.kconfig
    ghostty
    gnome-themes-extra
    iproute2
    iputils

    (chromium.override { commandLineArgs = "--no-first-run"; })
    bluetui
    bluetui-desktop
    cliamp
    cliamp-desktop
    firefox
    grim
    imv
    mpv
    nwg-displays
    wl-clipboard
    wl-mirror
    wtype
    proton-pass
    ente-desktop
    signal-desktop
    slack
    spotify
    zed-editor
  ];
}
