{ pkgs, ... }:
# The kaizen session every kaizen host shares, system half: niri under UWSM,
# portals, PAM, and the services the shell reads. home.nix holds the user half
# (the packages and data the shell runs), added here to every home-manager user.
# Units, scripts, compositor config and QML live in stow/kaizen/.
{
  imports = [ ../fonts.nix ];

  config = {
    home-manager.sharedModules = [ ./home.nix ];

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

    # Marks a kaizen host; dotfiles-stow stows stow/kaizen/ where it exists.
    environment.etc.kaizen.text = "";

    # The profiles home.nix's packages land in (useUserPackages) link only these
    # dirs; the shell finds its emoji data in share/kaizen.
    environment.pathsToLink = [ "/share/kaizen" ];

    environment.systemPackages = with pkgs; [
      # niri spawns it on demand and exports DISPLAY for X11 apps.
      xwayland-satellite
    ];
  };
}
