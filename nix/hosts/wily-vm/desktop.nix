{ lib, pkgs, ... }:
let
  # VM-only. UTM's virgl runs on ANGLE over Metal, which exposes desktop
  # OpenGL 2.1 (GLES tops out at 3.0). Ghostty is GTK4 and sets
  # GDK_DISABLE=gles-api itself, so it demands desktop GL >= 3.3 and dies with
  # "Unable to acquire an OpenGL context". llvmpipe gives it 4.6. Hyprland is
  # unaffected — it uses GLES 3.0 — so the override is scoped to this one
  # program rather than the session. Drop it on real hardware.
  ghostty-softgl = pkgs.symlinkJoin {
    name = "ghostty-softgl";
    paths = [ pkgs.ghostty ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/ghostty --set LIBGL_ALWAYS_SOFTWARE 1
    '';
  };

  # Runs for the graphical session's lifetime with a logind delay inhibitor.
  # PrepareForSleep gives the running Quickshell lock surface a bounded window
  # to become secure before the VM suspends. It lives in Nix rather than stow
  # so every dependency is an absolute store path in the generated wrapper.
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

  # Report silent failures in the alarm daemon, calendar sync, and Google token.
  calendar-watchdog = pkgs.writeShellApplication {
    name = "wily-calendar-watchdog";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.dbus
      pkgs.findutils
      pkgs.gnugrep
      pkgs.libnotify
    ];
    text = ''
      set -euo pipefail

      state_path="''${XDG_STATE_HOME:-"$HOME/.local/state"}/wily-calendar-watchdog-faults"
      cache_dir="$HOME/.cache/evolution/calendar"
      alarm_bus_name="org.gnome.Evolution-alarm-notify"
      sync_stall_seconds=$((2 * 60 * 60))
      declare -a faults=()

      notify_fault() {
        case "$1" in
          evolution-alarm-notify-unavailable)
            notify-send --app-name=wily-calendar-watchdog --urgency=critical \
              "Calendar reminder watchdog" \
              "Evolution's reminder notifier is not running; meeting alarms will not fire."
            ;;
          calendar-cache-missing)
            notify-send --app-name=wily-calendar-watchdog --urgency=critical \
              "Calendar reminder watchdog" \
              "No Evolution calendar cache was found; calendar sync cannot be verified."
            ;;
          calendar-sync-stalled)
            notify-send --app-name=wily-calendar-watchdog --urgency=critical \
              "Calendar reminder watchdog" \
              "Evolution's calendar cache has not updated for over two hours."
            ;;
          google-token-unavailable)
            notify-send --app-name=wily-calendar-watchdog --urgency=critical \
              "Calendar reminder watchdog" \
              "Google Online Accounts is unavailable or its access token could not be read."
            ;;
        esac
      }

      notify_recovery() {
        notify-send --app-name=wily-calendar-watchdog --expire-time=8000 \
          "Calendar reminder watchdog recovered" \
          "''${1//-/ } is healthy again."
      }

      add_fault() {
        faults+=("$1")
      }

      if ! busctl --user status "$alarm_bus_name" >/dev/null 2>&1; then
        add_fault evolution-alarm-notify-unavailable
      fi

      if [[ ! -d $cache_dir ]]; then
        add_fault calendar-cache-missing
      else
        newest_cache_mtime="$(
          find "$cache_dir" -mindepth 2 -maxdepth 2 -type f -name cache.db \
            ! -path "$cache_dir/trash/*" -printf '%T@\n' 2>/dev/null | sort -n | tail -n 1
        )"
        if [[ -z $newest_cache_mtime ]]; then
          add_fault calendar-cache-missing
        elif (( $(date +%s) - ''${newest_cache_mtime%%.*} > sync_stall_seconds )); then
          add_fault calendar-sync-stalled
        fi
      fi

      declare -a google_accounts=()
      while IFS= read -r account_path; do
        provider="$(busctl --user get-property org.gnome.OnlineAccounts "$account_path" \
          org.gnome.OnlineAccounts.Account ProviderType 2>/dev/null || true)"
        [[ $provider == 's "google"' ]] && google_accounts+=("$account_path")
      done < <(
        busctl --user tree org.gnome.OnlineAccounts 2>/dev/null |
          grep -o '/org/gnome/OnlineAccounts/Accounts/[^[:space:]]*' || true
      )

      if (( ''${#google_accounts[@]} == 0 )); then
        add_fault google-token-unavailable
      else
        for account_path in "''${google_accounts[@]}"; do
          if ! busctl --user call org.gnome.OnlineAccounts "$account_path" \
            org.gnome.OnlineAccounts.OAuth2Based GetAccessToken >/dev/null 2>&1; then
            add_fault google-token-unavailable
          fi
        done
      fi

      mkdir -p "$(dirname "$state_path")"
      previous_faults="$(mktemp "''${state_path}.XXXXXX")"
      current_faults="$(mktemp "''${state_path}.XXXXXX")"
      trap 'rm -f "$previous_faults" "$current_faults"' EXIT

      if [[ -f $state_path ]]; then
        sort -u "$state_path" > "$previous_faults"
      else
        : > "$previous_faults"
      fi
      if (( ''${#faults[@]} > 0 )); then
        printf '%s\n' "''${faults[@]}" | sort -u > "$current_faults"
      else
        : > "$current_faults"
      fi

      while IFS= read -r fault; do
        grep -Fxq "$fault" "$previous_faults" || notify_fault "$fault"
      done < "$current_faults"
      while IFS= read -r fault; do
        grep -Fxq "$fault" "$current_faults" || notify_recovery "$fault"
      done < "$previous_faults"

      mv "$current_faults" "$state_path"
    '';
  };
in
{
  # uwsm wraps the session in systemd units so graphical-session.target is
  # actually activated, which is what the Quickshell service below binds to.
  # Running the shell as its own unit also means it can be restarted without
  # touching the compositor — useful when iterating on the QML.
  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };

  # Hyprland's cursor manager reads these at startup; a config reload is too
  # late to replace the already-loaded cursor theme.
  environment.sessionVariables = {
    HYPRCURSOR_THEME = "macOS-hypr";
    HYPRCURSOR_SIZE = "24";
    # Chromium's wrapper reads this to opt into its native Wayland backend.
    NIXOS_OZONE_WL = "1";
  };

  # Terminal-first login: no display manager. Agetty authenticates fredrik on
  # the console, then the `hypr` zsh function starts this UWSM-managed session.
  # When it exits, the user returns to the same terminal rather than a greeter.
  # Keep programs.hyprland's graphical.target default: it does not start a
  # greeter, but UWSM's `check may-start` requires that target to be active.

  # Quickshell provides both the lock surface (PAM service below) and the
  # desktop polkit agent. NixOS owns the authorization daemon itself.
  security.polkit.enable = true;

  # Not implied by polkit.enable: without the setuid wrapper, pkexec aborts with
  # "pkexec must be setuid root" and never reaches the agent. D-Bus callers
  # (systemctl and friends) prompt either way.
  security.polkit.enablePkexecWrapper = true;

  # Keep this as a conventional PAM include rather than security.pam.services:
  # the current aarch64 nixpkgs PAM renderer evaluates disabled howdy/Kanidm
  # module paths and fails before it can render any custom service. PamContext
  # only calls pam_authenticate, and login's auth stack supplies pam_unix.
  environment.etc."pam.d/wily-lock".text = ''
    auth include login
  '';

  systemd.user.services.quickshell = {
    description = "Quickshell desktop shell";
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    # NixOS pins a sparse PATH on every user unit. Unsetting it is the only way
    # to let the unit inherit the session PATH uwsm imports into the user
    # manager, which is what the launcher needs: uwsm-app to spawn apps with,
    # and then every app's own Exec, which is a bare command name.
    environment.PATH = lib.mkForce null;
    # Quickshell ships no webp decoder; the wrapper prefixes its own plugin
    # paths to this, so the two sets merge. Omarchy's backgrounds are all webp.
    environment.QT_PLUGIN_PATH = "${pkgs.qt6.qtimageformats}/lib/qt-6/plugins";
    serviceConfig = {
      ExecStart = "${pkgs.quickshell}/bin/quickshell";
      Restart = "on-failure";
    };
  };

  # A delay inhibitor must already be active when logind broadcasts
  # PrepareForSleep. It is tied to the graphical target so its inherited
  # Quickshell IPC environment cannot leak into a later login session.
  systemd.user.services.wily-sleep-lock = {
    description = "Lock Quickshell before suspend";
    partOf = [ "graphical-session.target" ];
    after = [
      "dbus.socket"
      "graphical-session.target"
    ];
    requires = [ "dbus.socket" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${sleep-lock-monitor}/bin/wily-sleep-lock-monitor";
      Restart = "always";
      RestartSec = "2s";
    };
  };

  # Calendar reads EDS accounts; Evolution retains the Proton ICS wizard and
  # invitation fallback, while Google authentication is supplied by GOA.
  programs.evolution.enable = true;
  services.gnome.gnome-online-accounts.enable = true;
  # GOA refresh tokens are libsecret-backed and unlock through PAM at login.
  services.gnome.gnome-keyring.enable = true;
  programs.dconf.enable = true;

  # EDS already ships this Type=dbus service with ExecStart and Restart=on-failure.
  # A second instance exits after finding its D-Bus name owned, so only enable it.
  systemd.user.services.evolution-alarm-notify.wantedBy = [ "graphical-session.target" ];

  # Wall-clock scheduling lets Persistent catch a missed check after resume.
  systemd.user.services.wily-calendar-watchdog = {
    description = "Check calendar reminder dependencies";
    partOf = [ "graphical-session.target" ];
    after = [
      "dbus.socket"
      "graphical-session.target"
    ];
    requires = [ "dbus.socket" ];
    unitConfig.OnFailure = "wily-calendar-watchdog-failed.service";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${calendar-watchdog}/bin/wily-calendar-watchdog";
      # A D-Bus call stuck on a dead GOA process must become an observable
      # watchdog failure rather than blocking every later timer elapse.
      TimeoutStartSec = "1min";
    };
  };

  systemd.user.services.wily-calendar-watchdog-failed = {
    description = "Report a failed calendar reminder watchdog";
    partOf = [ "graphical-session.target" ];
    after = [
      "dbus.socket"
      "graphical-session.target"
    ];
    requires = [ "dbus.socket" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.libnotify}/bin/notify-send --app-name=wily-calendar-watchdog --urgency=critical \"Calendar reminder watchdog failed\" \"The watchdog itself crashed; inspect journalctl --user -u wily-calendar-watchdog.\"";
    };
  };

  systemd.user.timers.wily-calendar-watchdog = {
    description = "Periodically check calendar reminder dependencies";
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    timerConfig = {
      OnActiveSec = "2m";
      OnCalendar = "*:0/15";
      Persistent = true;
      Unit = "wily-calendar-watchdog.service";
    };
  };

  host.extraSystemPackages = with pkgs; [
    # Without --no-first-run the profile stays pinned to the light UI and
    # ignores the portal's color-scheme; see the browsers entry in CLAUDE.md.
    (chromium.override { commandLineArgs = "--no-first-run"; })
    firefox
    ghostty-softgl # terminal; see the let-block above
    gnome-calendar
    # EDS lacks Google's OAuth client; use GOA's small standalone account UI.
    gnome-online-accounts-gtk
    gnome-themes-extra # Adwaita-dark, the GTK theme the light/dark toggle names
    grim # screenshots, for verifying the session over SSH
    hyprsunset # nightlight; the schedule lives in the Quickshell service
    iproute2 # `ip` supplies the network panel's active route and counters
    iputils # `ping` supplies the network panel's latency and loss samples
    libnotify # notify-send smoke tests and CLI desktop notifications
    # proton-pass # unsupported on aarch64-linux; enable in the ThinkPad config
    quickshell
  ];
}
