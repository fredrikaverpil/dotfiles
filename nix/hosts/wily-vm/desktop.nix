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
  };

  # Autologin straight into Hyprland: no greeter UI, greetd only supplies the
  # session. greetd refuses to start unless default_session is set, even when
  # only initial_session is wanted. SSH stays up independently, so a crashing
  # session is recoverable.
  services.greetd = {
    enable = true;
    settings =
      let
        session = {
          command = "${pkgs.uwsm}/bin/uwsm start -F -e -D Hyprland ${pkgs.hyprland}/bin/start-hyprland";
          user = "fredrik";
        };
      in
      {
        initial_session = session;
        default_session = session;
      };
  };

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
    after = [ "dbus.socket" "graphical-session.target" ];
    requires = [ "dbus.socket" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${sleep-lock-monitor}/bin/wily-sleep-lock-monitor";
      Restart = "always";
      RestartSec = "2s";
    };
  };

  host.extraSystemPackages = with pkgs; [
    ghostty-softgl # terminal; see the let-block above
    grim # screenshots, for verifying the session over SSH
    libnotify # notify-send smoke tests and CLI desktop notifications
    quickshell
  ];
}
