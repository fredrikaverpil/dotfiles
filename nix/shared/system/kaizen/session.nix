{
  config,
  lib,
  pkgs,
  ...
}:
let
  # `[{ emoji, name, shortcodes }]`: Unicode's names for the menu's picker, and
  # the shortcodes Slack sends as `:name:` in notification text, from the
  # dataset Slack uses. Shortcode-only entries (skin tones) have a null name.
  emoji =
    pkgs.runCommand "emoji.json"
      {
        nativeBuildInputs = [ pkgs.jq ];
        names = "${pkgs.unicode-emoji}/share/unicode/emoji/emoji-test.txt";
        shortcodes = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/iamcal/emoji-data/v16.0.0/emoji.json";
          hash = "sha256-HWAuZb6Idyv4zDaM4WuFXXGe7duv4SjUcbgCA/SU0p8=";
        };
      }
      ''
        jq -nc --rawfile names "$names" --slurpfile data "$shortcodes" > $out '
          def hex: ascii_downcase | explode | reduce .[] as $c (0; . * 16 + if $c >= 97 then $c - 87 else $c - 48 end);
          ($data[0] | map({ key: [.unified | split("-")[] | hex] | implode, value: .short_names }) | from_entries) as $codes
          | [$names | split("\n")[] | capture("; fully-qualified +# (?<emoji>\\S+) E\\d+\\.\\d+ (?<name>.+)$") | select(.name | contains("skin tone") | not)] as $named
          | ($named | map({ key: .emoji, value: true }) | from_entries) as $seen
          | $named | map(.shortcodes = ($codes[.emoji] // []))
            + [$codes | to_entries[] | select($seen[.key] | not) | { emoji: .key, name: null, shortcodes: .value }]
        '
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
  # Lists the shell's IPC functions, all targets or one, sorted by target.
  kaizen-ipc = pkgs.writeShellApplication {
    name = "kaizen-ipc";
    runtimeInputs = [
      pkgs.gawk
      pkgs.quickshell
    ];
    text = ''
      qs ipc show |
        awk -v t="''${1:-}" '/^target /{n=$2} t=="" || n==t {print n "\t" $0}' |
        sort -s -t "$(printf '\t')" -k1,1 |
        cut -f2-
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
# the shell's user units and the pre-suspend lock, the services and packages the
# shell and its binds use, and its notification rules. Compositor config and QML
# live in stow/kaizen/.
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
            urgency = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.enum [
                  "low"
                  "normal"
                  "critical"
                ]
              );
              default = null;
              description = "Urgency in place of the one the app sent; critical sticks and bypasses Do Not Disturb, low expires sooner. The first matching rule with one applies";
            };
            border = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.enum [
                  "rose"
                  "leaf"
                  "wood"
                  "water"
                  "blossom"
                  "sky"
                ]
              );
              default = null;
              description = "Palette colour of the toast's border, in place of the one its urgency gives";
            };
            borderAnimation = lib.mkOption {
              type = lib.types.nullOr (lib.types.enum [ "orbit" ]);
              default = null;
              description = "Animation of the border: `orbit` keeps a dash travelling around it, and dims the border itself so the dash stands out";
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
            collapse = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.submodule {
                  options = {
                    summary = lib.mkOption {
                      type = lib.types.nullOr lib.types.str;
                      default = null;
                      description = "Summary in place of the latest toast's";
                    };
                    body = lib.mkOption {
                      type = lib.types.nullOr lib.types.str;
                      default = null;
                      description = "Body in place of the latest toast's";
                    };
                  };
                }
              );
              default = null;
              example = {
                body = "Several new review requests";
              };
              description = "Show a burst of this rule's toasts as one: each is held briefly, then the latest replaces the others and the one on screen, showing these fields in place of its own. A lone toast keeps the app's text";
            };
            focus = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              example = "^chrome-calendar\\.google\\.com";
              description = "JavaScript regex of the app id of the window to focus when the notification is activated, in place of the notification's own app";
            };
            icon = lib.mkOption {
              type = lib.types.nullOr lib.types.path;
              default = null;
              example = lib.literalExpression "./github.svg";
              description = "Icon shown in place of the notification's, such as the sender an app relays for; the notification's own moves to a badge on its corner";
            };
            badge = lib.mkOption {
              type = lib.types.nullOr lib.types.path;
              default = null;
              example = lib.literalExpression "./heart.svg";
              description = "Icon on the corner badge, in place of the notification's own when `icon` moves it there";
            };
            actions = lib.mkOption {
              type = lib.types.listOf (
                lib.types.submodule {
                  options = {
                    label = lib.mkOption {
                      type = lib.types.str;
                      description = "Text of the button";
                    };
                    command = lib.mkOption {
                      type = lib.types.listOf lib.types.str;
                      example = [
                        "notify-send"
                        "Pressed"
                      ];
                      description = "Program and arguments, run detached and not in a shell";
                    };
                    env = lib.mkOption {
                      type = lib.types.attrsOf lib.types.str;
                      default = { };
                      description = "Variables added to the command's environment, besides NOTIFICATION_APP, NOTIFICATION_SUMMARY and NOTIFICATION_BODY";
                    };
                  };
                }
              );
              default = [ ];
              description = "Buttons after the toast's own; pressing one runs its command and dismisses the toast. The first matching rule with any applies";
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
      environment.KAIZEN_EMOJI = "${emoji}";
      environment.KAIZEN_NOTIFICATION_RULES = "${pkgs.writeText "notification-rules.json" (
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
        urgency = "critical";
        border = "leaf";
        dedup = {
          group = "calendar";
          keep = true;
        };
        # The reminder comes from Chromium, but the window is the Calendar app's.
        focus = "^chrome-calendar\\.google\\.com";
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
        urgency = "critical";
        border = "leaf";
        dedup.group = "calendar";
        # Slack relays the reminder, but the event is in the Calendar app.
        focus = "^chrome-calendar\\.google\\.com";
        icon = ./icons/google-calendar.svg;
      }
      {
        match = {
          app = "^Slack$";
          summary = " from GitHub$";
        };
        icon = ./icons/github.svg;
      }
      # A pull request opened across many repos assigns its reviews in a burst.
      {
        match = {
          app = "^Slack$";
          summary = " from GitHub$";
          body = "^Reviews assigned to you on ";
        };
        collapse.body = "Several new review requests";
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
      kaizen-ipc
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
