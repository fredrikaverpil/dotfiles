{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Shortcode -> emoji, for apps (Slack) that send `:name:` in notification text.
  emoji-shortcodes =
    pkgs.runCommand "emoji-shortcodes.json"
      { nativeBuildInputs = [ (pkgs.python3.withPackages (p: [ p.emoji ])) ]; }
      ''
        python3 - > $out <<'EOF'
        import json, emoji
        codes = {}
        for char, data in emoji.EMOJI_DATA.items():
            for name in [data["en"], *data.get("alias", [])]:
                codes.setdefault(name.strip(":"), char)
        for tone, char in enumerate("🏻🏼🏽🏾🏿", start=2):
            codes[f"skin-tone-{tone}"] = char
        json.dump(codes, open(1, "w", encoding="utf-8", closefd=False), ensure_ascii=False)
        EOF
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
    text = ''
      lock_and_wait() {
        qs ipc call lock lock >/dev/null || return 1

        for _ in $(seq 1 30); do
          if qs ipc call lock status 2>/dev/null | grep -q '"secure":true'; then
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
  # Focuses the most recently focused niri window whose app id matches, or runs
  # the command when none does. niri's binds call it.
  kaizen-focus = pkgs.writeShellApplication {
    name = "kaizen-focus";
    runtimeInputs = [
      pkgs.jq
      config.programs.niri.package
    ];
    text = ''
      case "''${1:-}" in
      "" | -h | --help)
        echo "usage: kaizen-focus APP_ID_REGEX COMMAND [ARGS...]    focus the app, or open it"
        exit 0
        ;;
      esac

      regex="$1"
      shift
      id="$(niri msg -j windows | jq --arg re "$regex" \
        '[.[] | select(.app_id | test($re))] | max_by(.focus_timestamp | [.secs, .nanos]) | .id // empty')"
      if [ -n "$id" ]; then
        exec niri msg action focus-window --id "$id"
      fi
      exec "$@"
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
in
# The kaizen session every kaizen host shares: niri under UWSM, portals, PAM,
# the shell's user units and the pre-suspend lock, what the shell runs and its
# notification rules. Compositor config and QML live in stow/kaizen/.
{
  imports = [ ../fonts.nix ];

  options = {
    host.notificationRules = lib.mkOption {
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

    host.kaizenPlugins = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = "Shell plugin directories, each holding a Plugin.qml, loaded in order. A path is copied to the store; an absolute path as a string is read in place, and `qs ipc call shell reload` applies its edits";
    };
  };

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
      # Quickshell unsets systemd's sparse PATH below; removing that breaks launcher entries and uwsm-app.
      wantedBy = [ "wayland-session@niri.target" ];
      # NixOS pins a sparse user-unit PATH; inherit UWSM's session PATH for app launchers.
      environment.PATH = lib.mkForce null;
      # qtimageformats supplies Quickshell's WebP decoder.
      environment.QT_PLUGIN_PATH = "${pkgs.qt6.qtimageformats}/lib/qt-6/plugins";
      # The menu's emoji picker reads names from Unicode's test file.
      environment.EMOJI_TEST = "${pkgs.unicode-emoji}/share/unicode/emoji/emoji-test.txt";
      environment.EMOJI_SHORTCODES = "${emoji-shortcodes}";
      environment.NOTIFICATION_RULES = "${pkgs.writeText "notification-rules.json" (
        builtins.toJSON config.host.notificationRules
      )}";
      environment.KAIZEN_PLUGINS = lib.concatStringsSep ":" config.host.kaizenPlugins;
      serviceConfig = {
        ExecStart = "${pkgs.quickshell}/bin/quickshell";
        Restart = "on-failure";
        # Creates ~/.local/state/kaizen-shell before ExecStart: for user units
        # StateDirectory resolves under $XDG_STATE_HOME.
        StateDirectory = "kaizen-shell";
      };
    };

    # Holds XDG autostart apps (UWSM orders them after this target) until the tray's
    # StatusNotifierWatcher is up; Electron apps look for it once and never retry.
    # The shell registers it once its config loads, which waits for xdg-desktop-portal,
    # itself ordered after graphical-session.target: waiting in quickshell.service would deadlock.
    systemd.user.services.kaizen-tray-ready = {
      description = "Wait for the Quickshell tray";
      before = [ "wayland-session-xdg-autostart@niri.target" ];
      wantedBy = [ "wayland-session-xdg-autostart@niri.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.bash}/bin/bash -c 'until ${pkgs.systemd}/bin/busctl --user status org.kde.StatusNotifierWatcher >/dev/null 2>&1; do ${pkgs.coreutils}/bin/sleep 0.2; done'";
        # A tray that never comes up delays autostart apps, never blocks them.
        TimeoutStartSec = 10;
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

    host.notificationRules = [
      # Google Calendar reminders arrive from both Slack and Chromium; Chromium's
      # copy carries the buttons.
      {
        # Chromium prefixes the body with the origin.
        match = {
          app = "^Chromium$";
          body = "^calendar\\.google\\.com\\n";
        };
        critical = true;
        dedup = {
          group = "calendar";
          keep = true;
        };
      }
      # Slack titles messages from its apps "[workspace] from <app>", as it does a
      # person's. Icons are simple-icons 16.32.0 (CC0) glyphs from
      # https://cdn.jsdelivr.net/npm/simple-icons@16.32.0/icons/<slug>.svg, filled
      # with the slug's `hex` from the package's data/simple-icons.json and scaled
      # onto a white circle:
      #   <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
      #     <circle cx="12" cy="12" r="12" fill="#fff"/>
      #     <path transform="translate(5 5) scale(.5833)" fill="#<hex>" d="<path>"/>
      #   </svg>
      {
        match = {
          app = "^Slack$";
          summary = " from Google Calendar$";
        };
        critical = true;
        dedup.group = "calendar";
        icon = ./icons/google-calendar.svg;
      }
      {
        match = {
          app = "^Slack$";
          summary = " from GitHub$";
        };
        icon = ./icons/github.svg;
      }
      {
        match = {
          app = "^Slack$";
          summary = " from Linear$";
        };
        icon = ./icons/linear.svg;
      }
    ];

    environment.systemPackages = with pkgs; [
      quickshell
      # niri's terminal binds and xdg-terminal-exec open it.
      ghostty
      # niri spawns it on demand and exports DISPLAY for X11 apps.
      xwayland-satellite
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
      grim
      imagemagick # Wallpaper thumbnails.
      jq # The clipboard watcher's JSON encoding.
      kaizen-focus
      mpv
      # nm-connection-editor edits wired, static-IP and other connection settings;
      # the network panel launches it. nm-applet runs via XDG autostart for its tray menu.
      networkmanagerapplet
      # Annotates screenshots from the notification's Edit action.
      satty
      wl-clipboard
    ];
  };
}
