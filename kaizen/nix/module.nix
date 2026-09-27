# The kaizen desktop: niri + Quickshell under UWSM, started with `kaizen` from
# the console. Packages, portals, PAM, user units and the pre-suspend lock.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.kaizen;

  sleep-lock-monitor = pkgs.writeShellApplication {
    name = "kaizen-sleep-lock-monitor";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.dbus
      pkgs.gnugrep
      pkgs.quickshell
      pkgs.systemd
    ];
    text = ''
      lock_and_wait() {
        qs -c kaizen ipc call lock lock >/dev/null || return 1

        for _ in $(seq 1 30); do
          if qs -c kaizen ipc call lock status 2>/dev/null | grep -q '"secure":true'; then
            echo "kaizen: session lock is secure, releasing the suspend delay"
            return 0
          fi
          sleep 0.1
        done

        return 1
      }

      monitor_sleep() {
        while IFS= read -r line; do
          if [[ $line == *"boolean true"* ]]; then
            lock_and_wait || echo "kaizen: session lock was not secure before suspend" >&2
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
          --who=kaizen \
          --why="Secure the Quickshell lock screen before suspend" \
          "$0" --monitor
      fi
    '';
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

  palette =
    variant:
    lib.mkOption {
      type = lib.types.submodule {
        options =
          lib.mapAttrs
            (
              role: use:
              lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "${use}; zenbones when null";
              }
            )
            {
              bg = "Background";
              fg = "Text and icons";
              sel = "Selected and focused rows";
              dim = "Borders, dividers and tracks";
              off = "Secondary and inactive text";
              alert = "Errors, critical notifications and muted devices";
              warn = "Low battery";
              accent = "niri's active window border";
            };
      };
      default = { };
      example = {
        bg = "#1E1E2E";
        accent = "#89B4FA";
      };
      description = "Colours of the ${variant} theme by role, as #RRGGBB";
    };
in
{
  options.programs.kaizen = {
    enable = lib.mkEnableOption "the kaizen desktop";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./package.nix { };
      defaultText = lib.literalExpression "pkgs.callPackage ./package.nix { }";
      description = "The kaizen package";
    };

    theme = {
      dark = palette "dark";
      light = palette "light";
    };

    font = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "Maple Mono";
      description = "Font family of the shell, used when installed; otherwise JetBrainsMono Nerd Font, which also supplies the icons";
    };

    notificationRules = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            match = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              example = {
                app = "^Slack$";
                summary = " in #?alerts$";
              };
              description = "JavaScript regexes keyed by notification field (app, summary, body); the rule applies when all match";
            };
            critical = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Raise to critical, so it sticks and bypasses Do Not Disturb";
            };
            dedup = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.submodule {
                  options = {
                    group = lib.mkOption {
                      type = lib.types.str;
                      description = "One event reported by several apps";
                    };
                    keep = lib.mkOption {
                      type = lib.types.bool;
                      default = false;
                      description = "Show this copy and dismiss the group's others; they are held briefly in case it arrives";
                    };
                  };
                }
              );
              default = null;
              description = "Show one copy of an event reported by several apps";
            };
            icon = lib.mkOption {
              type = lib.types.nullOr lib.types.path;
              default = null;
              example = lib.literalExpression "./github.svg";
              description = "Icon shown in place of the notification's, such as the sender an app relays for; the notification's own moves to a badge on its corner";
            };
          };
        }
      );
      default = [ ];
      description = "Kaizen's notification rules";
    };
  };

  config = lib.mkIf cfg.enable {
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

    # The setcap wrapper spares screen capture pkexec's root prompt.
    programs.gpu-screen-recorder.enable = true;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    security.rtkit.enable = true;

    # The shell's battery service reads UPower and power-profiles-daemon over D-Bus.
    # power-profiles-daemon conflicts with TLP and tuned, hence mkDefault.
    services.upower.enable = true;
    services.power-profiles-daemon.enable = lib.mkDefault true;

    # GTK3 needs the portal to follow the dconf theme; Qt uses the GTK platform theme.
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      QT_QPA_PLATFORMTHEME = "gtk3";
      GTK_USE_PORTAL = "1";
    };

    # polkit.enable does not install the setuid pkexec wrapper.
    security.polkit.enablePkexecWrapper = true;

    # PAM service for the Quickshell lock screen (plugins/lock/Service.qml).
    # The lock screen starts PAM only after a password is submitted, so fprintd in
    # this stack would block typing; fingerprint unlock needs a separate PamContext.
    environment.etc."pam.d/kaizen-lock".text = ''
      auth include login
    '';

    # `quickshell -c kaizen` finds it through XDG_CONFIG_DIRS; a
    # ~/.config/quickshell/kaizen takes precedence.
    environment.etc."xdg/quickshell/kaizen".source = "${cfg.package}/share/kaizen/shell";

    # For the user's niri config to include: kaizen.kdl (required) and
    # kaizen-binds.kdl.
    environment.etc."kaizen/niri".source = "${cfg.package}/share/kaizen/niri";

    systemd.user.services.kaizen-shell = {
      description = "Quickshell desktop shell";
      partOf = [ "graphical-session.target" ];
      # Never order after graphical-session.target: that creates a systemd cycle.
      # waitenv closes niri's readiness-before-WAYLAND_DISPLAY race.
      after = [
        "wayland-wm@niri.service"
        "wayland-session-waitenv.service"
      ];
      # Bind to the niri session so another desktop cannot start a second shell.
      # Quickshell unsets systemd's sparse PATH below; removing that breaks launcher entries and uwsm-app.
      wantedBy = [ "wayland-session@niri.target" ];
      # NixOS pins a sparse user-unit PATH; inherit UWSM's session PATH for app launchers.
      environment.PATH = lib.mkForce null;
      environment.NOTIFICATION_RULES = "${pkgs.writeText "notification-rules.json" (
        builtins.toJSON cfg.notificationRules
      )}";
      environment.KAIZEN_THEME = builtins.toJSON (
        lib.mapAttrs (_: lib.filterAttrs (_: colour: colour != null)) cfg.theme
      );
      environment.KAIZEN_FONT = cfg.font;
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/kaizen-shell";
        Restart = "on-failure";
        # Creates ~/.local/state/kaizen-shell before ExecStart: for user units
        # StateDirectory resolves under $XDG_STATE_HOME.
        StateDirectory = "kaizen-shell";
      };
    };

    # Lid close and the power key suspend via logind; this delay inhibitor locks
    # the shell first and releases once the lock reports secure.
    systemd.user.services.kaizen-sleep-lock = {
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
        ExecStart = "${sleep-lock-monitor}/bin/kaizen-sleep-lock-monitor";
        Restart = "always";
        RestartSec = "2s";
      };
    };

    environment.systemPackages = with pkgs; [
      cfg.package
      quickshell
      # niri spawns it on demand and exports DISPLAY for X11 apps.
      xwayland-satellite
      # Nightlight: drives zwlr_gamma_control_v1, so it is compositor-agnostic.
      wl-gammarelay-rs
      libnotify
      sound-theme-freedesktop
      gnome-themes-extra
      # Cursor theme for niri, GTK and Qt; without one niri draws a fixed 64px fallback.
      bibata-cursors
      iproute2
      iputils
      grim
      # Annotates screenshots from the notification's Edit action.
      satty
      wl-clipboard
      mpv
      imagemagick
      curl
      jq
      kdePackages.kconfig
      bluetui
      bluetui-desktop
      # nm-connection-editor edits wired, static-IP and other connection settings;
      # the network panel launches it. nm-applet runs via XDG autostart for its tray menu.
      networkmanagerapplet
      mission-center
    ];

    # Ui/Fonts.qml falls back to JetBrainsMono Nerd Font; icons are Nerd Font glyphs.
    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only
      noto-fonts-color-emoji
    ];
  };
}
