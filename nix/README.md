# Nix

Where software and settings are declared. Declare each once, in the narrowest
place that covers every host that wants it.

## Where does it go?

Go down the list; the first match wins.

1. **kaizen core**: `shared/system/kaizen/session.nix`. Part of kaizen's design:
   the shell, the session or a bind in `stow/kaizen/` needs it to do its job.
   That covers the bar and its panels, the launcher, the lock, recording,
   screenshots and wallpapers, and the purpose-built apps kaizen hands tasks to
   (bluetui, nm-connection-editor). An app kaizen only opens as a convenience,
   such as Mission Center from the system alert indicator, stays an app until
   kaizen integrates it.
2. **kaizen plugin**: `shared/system/kaizen/plugins/<name>/`, imported by the
   hosts that want it. Written for kaizen: a `Plugin.qml`, a daemon the shell
   queries, or a tray app built for the shell. A third-party app with a tray
   icon is an app, not a plugin; the tray shows it anyway.
3. **Hardware class**: `shared/system/thinkpad.nix`.
4. **Anything else is an app or a host setting**, and kaizen does not decide
   it. Pick the scope, then system or user.

| Wanted on                     | System                           | User                            |
| ----------------------------- | -------------------------------- | ------------------------------- |
| every host                    | `shared/system/common.nix`       | `shared/home/common.nix`        |
| every NixOS host, servers too | `shared/system/linux.nix`        | `shared/home/linux.nix`         |
| every macOS host              | `shared/system/darwin.nix`       | `shared/home/darwin.nix`        |
| every NixOS desktop host      | `shared/system/desktop.nix`      | `shared/home/desktop.nix`       |
| one host                      | `hosts/<host>/configuration.nix` | `hosts/<host>/users/<user>.nix` |

- **System**: GUI apps, and anything that needs a NixOS or nix-darwin module
  (a service, the firewall, a setuid wrapper). On macOS, GUI apps are Homebrew
  casks.
- **User** (home-manager): CLI tools, so macOS and the servers share them, and
  home-manager-only options such as the web apps' `xdg.desktopEntries`.

Something one host wants is declared in that host. Once every host in a scope
wants it, move it to that scope's shared file rather than repeating it.

## Desktop hosts

A desktop host imports `shared/system/desktop.nix` for its apps and opts into
kaizen with `shared/system/kaizen/session.nix` and any plugins. Servers import
neither. Apps build on kaizen, never the reverse: `desktop.nix` and the hosts
set kaizen's options, such as its notification rules, and kaizen refers to no
app.

An app's niri window rules and binds go in
`stow/host/renoir/.config/niri/apps.kdl`, which wily symlinks, or the host's
`host.kdl`.

On a kaizen host, wrap Chromium and Electron apps with
`pkgs.withGnomeLibsecret` (`shared/overlays/`); without it they cannot keep
logins in gnome-keyring.

An app starts with the session through XDG autostart:
`pkgs.makeAutostartItem` next to it in the package list. UWSM runs each entry
as `app-<name>@autostart.service`. kaizen holds autostart until its tray is up,
so a tray icon registers on the first try. Write a systemd user unit only for a
daemon that needs restarts, ordering or start checks, which XDG autostart lacks.
