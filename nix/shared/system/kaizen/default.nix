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
        bash ${../../../../stow/kaizen/.local/libexec/kaizen/emoji} "$names" "$shortcodes" > $out/share/kaizen/emoji.json
      '';

  # qtimageformats supplies Quickshell's WebP decoder.
  quickshell = pkgs.symlinkJoin {
    inherit (pkgs.quickshell) name meta;
    paths = [ pkgs.quickshell ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      for bin in $out/bin/*; do
        wrapProgram "$bin" --prefix QT_PLUGIN_PATH : ${pkgs.qt6.qtimageformats}/lib/qt-6/plugins
      done
    '';
  };
in
# The kaizen session every kaizen host shares: niri under UWSM, portals, PAM,
# the services the shell reads, and the packages and data its shell, binds,
# scripts and units run. Units, scripts, compositor config, QML and
# notification rules live in stow/kaizen/.
{
  imports = [ ../fonts.nix ];

  config = {
    # niri is the only session: `niri --session` under UWSM, started with `kaizen` from the console.
    programs.uwsm.enable = true;

    # Session defaults, GNOME (screencast) and GTK portals, gnome-keyring as Secret Service,
    # and Nautilus as the GNOME portal's file chooser (useNautilus defaults on).
    # Its niri.service, session file and swaylock PAM go unused under UWSM.
    # gnome-keyring is unlocked by the login PAM stack; fingerprint login cannot unlock it.
    programs.niri.enable = true;
    # niri's module leaves Xwayland off; xwayland-satellite runs the Xwayland binary.
    programs.xwayland.enable = true;

    # uwsm-app launches Terminal=true entries through xdg-terminal-exec.
    xdg.terminal-exec.enable = true;
    xdg.terminal-exec.settings.default = [ "com.mitchellh.ghostty.desktop" ];

    # The setcap wrapper lets monitor capture skip the portal dialog.
    programs.gpu-screen-recorder.enable = true;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    security.rtkit.enable = true;

    # The shell's battery service reads UPower and power-profiles-daemon over D-Bus.
    # power-profiles-daemon conflicts with TLP; keep TLP disabled.
    services.upower.enable = true;
    services.power-profiles-daemon.enable = true;

    # BlueZ does not persist Powered; the shell's panel only toggles power and
    # connects paired devices, pairing belongs to bluetui.
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    # The shell's network service and panel drive NetworkManager through nmcli.
    networking.networkmanager.enable = true;

    # BIOS and device firmware from LVFS. Updates reboot, so the user runs them:
    #
    #   fwupdmgr refresh --force               # stale metadata reports "no updates"
    #   fwupdmgr get-updates                   # lists each device's "Device ID"
    #   cat /sys/class/power_supply/AC/online  # must print 1
    #   fwupdmgr update <device-id>
    #
    # A BIOS update needs AC power and reboots into a UEFI capsule flash staged on
    # the ESP (/boot); keep room there. It can reset EFI settings. Afterwards,
    # confirm /sys/class/dmi/id/bios_version and recheck
    # `journalctl -b -k -p warning`. The Secure Boot databases (KEK, db, dbx) are
    # unused while Secure Boot is disabled, but applying them is harmless: the dbx
    # update refuses when it would revoke a binary on the ESP. Update only the
    # device you need, by ID.
    services.fwupd.enable = true;

    # GTK3 needs the portal to follow the dconf theme; Qt uses the GTK platform theme.
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      QT_QPA_PLATFORMTHEME = "gtk3";
      GTK_USE_PORTAL = "1";
    };

    # polkit.enable does not install the setuid pkexec wrapper.
    security.polkit.enablePkexecWrapper = true;

    # PAM service for the Quickshell lock screen (modules/lock/Service.qml).
    # The lock screen starts PAM only after a password is submitted, so fprintd in
    # this stack would block typing; fingerprint unlock needs a separate PamContext.
    environment.etc."pam.d/kaizen-lock".text = ''
      auth include login
    '';

    # Marks a kaizen host; stow.sh stows stow/kaizen/ where it exists.
    environment.etc.kaizen.text = "";

    # The system profile links only these dirs; the shell finds its emoji data
    # in share/kaizen.
    environment.pathsToLink = [ "/share/kaizen" ];

    environment.systemPackages = with pkgs; [
      # niri spawns it on demand and exports DISPLAY for X11 apps.
      xwayland-satellite
      # The wrapper above (let outranks with); the shell's unit finds it on PATH.
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
      emoji
      grim
      imagemagick # Wallpaper thumbnails.
      jq # The clipboard watcher's JSON encoding, `kaizen focus` and `kaizen doctor`.
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
