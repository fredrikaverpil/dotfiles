# Nix

## Common commands

```sh
# rebuild/switch after initial switch
nh os switch --ask  # NixOS
nh darwin switch --ask  # macOS

# run stowing of files
dotfiles-stow

# update all flake inputs
nix flake update

# update only specific input
nix flake update llm-agents  # example

# clean up old generations
sudo nix-collect-garbage --delete-older-than 5d

# update homebrew packages on macOS
brew update && brew upgrade   # add --greedy to also bump self-updating casks
```

> [!NOTE]
>
> Pinning Homebrew versions is possible via
> [nix-homebrew](https://github.com/zhaofengli/nix-homebrew) with locked taps,
> but it buys little here: casks that self-update ignore the pin, vendors delete
> old cask artifacts, and Mac App Store apps cannot be pinned at all.

## Where does it go?

Where software and settings are declared. Declare each once, in the narrowest
place that covers every host that wants it.

Go down the list; the first match wins.

1. **kaizen core**:
   [`shared/system/kaizen/session.nix`](shared/system/kaizen/session.nix). What
   the shell, the session or a bind in [`stow/kaizen/`](../stow/kaizen/) needs
   to do its job, including the purpose-built apps kaizen hands tasks to
   (bluetui, nm-connection-editor).
2. **kaizen plugin**: optional; the shell runs without it. Written for kaizen,
   not a third-party app with a tray icon. Paths are in
   [`../KAIZEN.md`](../KAIZEN.md) › Where it lives.
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

- **System**: GUI apps, and anything that needs a NixOS or nix-darwin module
  (a service, the firewall, a setuid wrapper). On macOS, GUI apps are Homebrew
  casks.
- **User** (home-manager): CLI tools, so macOS and the servers share them, and
  home-manager-only options such as the web apps' `xdg.desktopEntries`.

Something one host wants is declared in that host. Once every host in a scope
wants it, move it to that scope's shared file rather than repeating it.

## Desktop hosts

A desktop host imports
[`shared/system/linux-desktop.nix`](shared/system/linux-desktop.nix) for its
apps and opts into kaizen with
[`shared/system/kaizen/session.nix`](shared/system/kaizen/session.nix) and any
plugins. Servers import neither. The two stay independent: `linux-desktop.nix`
sets no kaizen option, and kaizen declares everything it runs, even a tool
another scope also installs (`jq`, `imagemagick`). kaizen's own settings, such
as its notification rules, may name apps; a host adds to them in its own
configuration. [`../KAIZEN.md`](../KAIZEN.md) maps kaizen's own parts, Nix and
Stow.

An app's niri window rules and binds go in
`stow/host/<hostname>/.config/niri/apps.kdl` (example in
[`stow/host/renoir/.config/niri/apps.kdl`](../stow/host/renoir/.config/niri/apps.kdl)),
which wily symlinks, or the host's `host.kdl`.

On a kaizen host, wrap Chromium and Electron apps with `pkgs.withGnomeLibsecret`
([`shared/overlays/`](shared/overlays/)); without it they cannot keep logins in
gnome-keyring.

An app starts with the session through XDG autostart:
`pkgs.makeAutostartItem` next to it in the package list. UWSM runs each entry
as `app-<name>@autostart.service`. kaizen holds autostart until its tray is up,
so a tray icon registers on the first try. Write a systemd user unit only for a
daemon that needs restarts, ordering or start checks, which XDG autostart lacks.
