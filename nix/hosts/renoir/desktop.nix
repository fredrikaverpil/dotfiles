{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
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
  imports = [ inputs.dankcalendar.nixosModules.default ];

  programs.uwsm.enable = true;

  # OAuth tokens stay in gnome-keyring (from programs.niri), unlocked by the login PAM stack.
  programs.dank-calendar.enable = true;

  # Session defaults, GNOME (screencast) and GTK portals, gnome-keyring as Secret Service,
  # and Nautilus as the GNOME portal's file chooser.
  programs.niri.enable = true;
  # gnome-keyring would also start gcr-ssh-agent as the SSH agent.
  services.gnome.gcr-ssh-agent.enable = false;
  # Nautilus's trash, network locations and removable media.
  services.gvfs.enable = true;
  # niri's module leaves Xwayland off; xwayland-satellite runs the Xwayland binary.
  programs.xwayland.enable = true;

  # Opens port 53317 for receiving files and text from the iPhone.
  programs.localsend.enable = true;

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

  # uwsm-app launches Terminal=true entries through xdg-terminal-exec.
  xdg.terminal-exec = {
    enable = true;
    settings.default = [ "com.mitchellh.ghostty.desktop" ];
  };

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
    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORMTHEME = "gtk3";
    GTK_USE_PORTAL = "1";
  };

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
      "wayland-wm@niri.service"
      "wayland-session-waitenv.service"
    ];
    # Bind to the niri session so another desktop cannot start a second shell.
    wantedBy = [ "wayland-session@niri.target" ];
    # NixOS pins a sparse user-unit PATH; inherit UWSM's session PATH for app launchers.
    environment.PATH = lib.mkForce null;
    # qtimageformats supplies Quickshell's WebP decoder.
    environment.QT_PLUGIN_PATH = "${pkgs.qt6.qtimageformats}/lib/qt-6/plugins";
    # The menu's emoji picker reads names from Unicode's test file.
    environment.EMOJI_TEST = "${pkgs.unicode-emoji}/share/unicode/emoji/emoji-test.txt";
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
      "wayland-wm@niri.service"
      "wayland-session-waitenv.service"
    ];
    wantedBy = [ "wayland-session@niri.target" ];
    # NixOS pins a sparse user-unit PATH; inherit UWSM's session PATH so dcal can
    # launch its Quickshell UI and open OAuth URLs with the session's tools.
    environment.PATH = lib.mkForce null;
    # Retry indefinitely, e.g. while the keyring is not yet unlocked.
    unitConfig.StartLimitIntervalSec = 0;
    serviceConfig = {
      # OpenSession prevents the weak local fallback; the collection probe catches broken first-use initialization.
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
  };

  systemd.user.services.wily-sleep-lock = {
    description = "Lock Quickshell before suspend";
    partOf = [ "graphical-session.target" ];
    # Match Quickshell's ordering: waitenv is required for niri, and graphical-session.target cycles.
    after = [
      "dbus.socket"
      "wayland-wm@niri.service"
      "wayland-session-waitenv.service"
    ];
    requires = [ "dbus.socket" ];
    wantedBy = [ "wayland-session@niri.target" ];
    serviceConfig = {
      ExecStart = "${sleep-lock-monitor}/bin/wily-sleep-lock-monitor";
      Restart = "always";
      RestartSec = "2s";
    };
  };

  host.extraSystemPackages = with pkgs; [
    quickshell
    # niri spawns it on demand and exports DISPLAY for X11 apps.
    xwayland-satellite
    wl-gammarelay-rs
    libnotify
    sound-theme-freedesktop
    kdePackages.dolphin
    # Dolphin thumbnails for images and videos.
    kdePackages.kio-extras
    kdePackages.ffmpegthumbs
    kdePackages.kconfig
    # Trialled side by side with Dolphin.
    nautilus
    ghostty
    gnome-themes-extra
    iproute2
    iputils

    # Chromium picks its password store per desktop; switching stores drops cookies and logins.
    (chromium.override { commandLineArgs = "--no-first-run --password-store=gnome-libsecret"; })
    bluetui
    bluetui-desktop
    btop
    cliamp
    cliamp-desktop
    firefox
    grim
    imv
    # Trims recordings by stream copy, without re-encoding.
    losslesscut-bin
    mission-center
    mpv
    # nm-connection-editor edits wired, static-IP and other connection settings.
    networkmanagerapplet
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
