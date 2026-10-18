# Nix

Where software and settings are declared. Declare each once, in the narrowest
place that covers every host that wants it.

## Where does it go?

Go down the list; the first match wins.

1. **kaizen core**:
   [`../kaizen/nix/`](../kaizen/nix/default.nix). What
   the shell, the session or a bind in [`kaizen/stow/`](../kaizen/stow/) needs
   to do its job, including the purpose-built apps kaizen hands tasks to
   (bluetui, nm-connection-editor).
2. **kaizen plugin**: optional; the shell runs without it. Written for kaizen,
   not a third-party app with a tray icon. Paths are in
   [`../kaizen/README.md`](../kaizen/README.md) › Where it lives.
3. **Hardware class**:
   [`shared/system/thinkpad.nix`](shared/system/thinkpad.nix).
4. **Anything else is an app or a host setting**, and kaizen does not decide
   it. Pick the scope, then system or user.

| Wanted on                     | System                            | User                            |
| ----------------------------- | --------------------------------- | ------------------------------- |
| every host                    | [`shared/system/common.nix`](shared/system/common.nix)        | [`shared/home/common.nix`](shared/home/common.nix)        |
| every NixOS host, servers too | [`shared/system/linux.nix`](shared/system/linux.nix)         | [`shared/home/linux.nix`](shared/home/linux.nix)         |
| every macOS host              | [`shared/system/darwin.nix`](shared/system/darwin.nix)        | [`shared/home/darwin.nix`](shared/home/darwin.nix)        |
| every NixOS desktop host      | [`shared/system/linux-desktop.nix`](shared/system/linux-desktop.nix) | [`shared/home/linux-desktop.nix`](shared/home/linux-desktop.nix) |
| one host                      | `hosts/<host>/configuration.nix`  | `hosts/<host>/users/<user>.nix` |

- **System**: the default for a package, and anything that needs a NixOS or
  nix-darwin module (a service, the firewall, a setuid wrapper). On macOS, GUI
  apps are Homebrew casks.
- **User** (home-manager): home-manager-only options such as the web apps'
  `xdg.desktopEntries`, and CLI tools that macOS and the servers share, since
  `environment.systemPackages` is NixOS-only.

Something one host wants is declared in that host. Once every host in a scope
wants it, move it to that scope's shared file rather than repeating it.

## Desktop hosts

A desktop host imports
[`shared/system/linux-desktop.nix`](shared/system/linux-desktop.nix) for its
apps and opts into kaizen with
[`../kaizen/nix/`](../kaizen/nix/default.nix) and any
plugins. Servers import neither. The two stay independent: `linux-desktop.nix`
sets no kaizen option, and kaizen declares everything it runs, even a tool
another scope also installs (`jq`, `imagemagick`). kaizen's own settings, such
as its notification rules, name only the apps kaizen runs (satty); rules for a
host's apps go in its own Stow tree. [`../kaizen/README.md`](../kaizen/README.md) maps
kaizen's own parts, Nix and Stow.

An app's niri window rules and binds go in
[`stow/host/renoir/.config/niri/config.kdl`](../stow/host/renoir/.config/niri/config.kdl)
(the app window rules, and the binds block's Apps part), which wily symlinks,
or in a host's `host.kdl`. Their umbriel twins go in each host's
`stow/host/<host>/.config/umbriel/config.toml`.

On a kaizen host, wrap Chromium and Electron apps with `pkgs.withGnomeLibsecret`
([`shared/overlays/`](shared/overlays/)); without it they cannot keep logins in
gnome-keyring.

An app starts with the session through XDG autostart:
`pkgs.makeAutostartItem` next to it in the package list. UWSM runs each entry
as `app-<name>@autostart.service`. kaizen holds autostart until its tray is up,
so a tray icon registers on the first try. Write a systemd user unit only for a
daemon that needs restarts, ordering or start checks, which XDG autostart lacks.
