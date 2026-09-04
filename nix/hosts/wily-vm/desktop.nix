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
  # cliamp is a TUI, so nixpkgs ships the bare binary and the launcher's apps
  # provider has no entry to find. Omarchy's convention for these is
  # Terminal=false plus an explicit terminal in Exec (applications/*.desktop);
  # theirs calls xdg-terminal-exec, which is not installed here. `ghostty` is a
  # bare command name, so it resolves through PATH to the softgl wrapper above.
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
  # uwsm wraps the session in systemd units so graphical-session.target is
  # actually activated, which is what the Quickshell service below binds to.
  # Running the shell as its own unit also means it can be restarted without
  # touching the compositor — useful when iterating on the QML.
  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };

  # xdg-desktop-portal keys its backend choice off XDG_CURRENT_DESKTOP, and
  # nothing declares one for "niri". Without this it finds no implementation
  # and every portal call fails -- including the Settings one that carries
  # org.freedesktop.appearance, which is what the light/dark toggle drives.
  # xdph is Hyprland-only, so gtk is the whole answer here; screencast under
  # niri would want xdg-desktop-portal-gnome instead.
  xdg.portal.config.niri.default = [ "gtk" ];

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  security.rtkit.enable = true;

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
    # Ordered against the compositor service, not graphical-session.target.
    # systemd orders a target after the units that are wantedBy it, and
    # graphical-session.target is itself after the session target below — so
    # `after = graphical-session.target` closes a cycle, which systemd breaks
    # by silently deleting this unit's start job. The session comes up with no
    # bar and no lock, and only the journal for graphical-session.target says
    # why.
    # Both compositors, and only one of them is ever in the start transaction,
    # so the unused After is inert.
    after = [
      "wayland-wm@hyprland.desktop.service"
      "wayland-wm@niri.service"
    ];
    # Not graphical-session.target: Plasma activates that too, and this shell
    # would then stack a second bar, lock surface and polkit agent onto KWin.
    wantedBy = [
      "wayland-session@hyprland.desktop.target"
      "wayland-session@niri.target"
    ];
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
    # See the quickshell unit above: an After on graphical-session.target is
    # an ordering cycle here.
    after = [
      "dbus.socket"
      "wayland-wm@hyprland.desktop.service"
      "wayland-wm@niri.service"
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

  # cliamp propagates yt-dlp, which pulls python3Packages.curl-cffi, whose test
  # suite fails on aarch64-linux: its localhost TLS tests reject the certificate
  # for 127.0.0.1. cache.nixos.org has no build of it either, so this is not a
  # local fault and no nixpkgs bump fixes it. The library itself is fine.
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
    hyprsunset # nightlight; the schedule lives in the Quickshell service
    niri # second compositor; the same Quickshell config runs under either
    # niri's nightlight backend. Hyprland dropped wlr-gamma-control for its own
    # CTM protocol, which is what hyprsunset speaks and this does not, so the
    # two are not interchangeable -- each compositor gets its own.
    wl-gammarelay-rs
    libnotify # notify-send smoke tests and CLI desktop notifications
    # GUI file manager; the launcher's apps provider picks up its .desktop
    # entry with no menu change. Pulls KDE Frameworks 6, and the rest of the
    # session has no KDE stack -- it is here for its keyboard coverage.
    kdePackages.dolphin
    ghostty-softgl # terminal; see the let-block above
    gnome-themes-extra # Adwaita-dark, the GTK theme the light/dark toggle names
    iproute2 # `ip` supplies the network panel's active route and counters
    iputils # `ping` supplies the network panel's latency and loss samples

    # Without --no-first-run the profile stays pinned to the light UI and
    # ignores the portal's color-scheme; see the browsers entry in CLAUDE.md.
    (chromium.override { commandLineArgs = "--no-first-run"; })
    cliamp # terminal Winamp; music player
    cliamp-desktop # its launcher entry; see the let-block above
    firefox
    grim # screenshots, for verifying the session over SSH
    signal-desktop
    # proton-pass # unsupported on aarch64-linux; enable in the ThinkPad config
    # spotify # unsupported on aarch64-linux; psst or spotify-qt if wanted here
  ];
}
