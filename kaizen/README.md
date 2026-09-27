# kaizen

kaizen is [niri](https://niri-wm.github.io/niri/) plus a
[Quickshell](https://quickshell.org) shell: a minimal, keyboard-first desktop
for NixOS. It adds a bar, a launcher that reaches everything, panels,
notifications, a lock screen, screenshots and screen recording. Your niri
config and keybindings stay yours.

It is built for its author's ThinkPads and published as is. There is no
stability promise before 1.0: options, IPC and the plugin contract may change.

## Try it

From a console login (a TTY, with no graphical session running):

```sh
nix run 'github:fredrikaverpil/dotfiles?dir=kaizen'
```

The host must run NixOS with `programs.uwsm.enable = true` (the trial runs
under uwsm's user units) and working graphics. The trial brings niri, the
shell, its tools and fonts. It uses its own niri config: niri's stock
window-management binds plus kaizen's. Mod+Space opens the launcher, Mod+T
your terminal (through `xdg-terminal-exec`) and Mod+Shift+E quits. Add your own
niri settings in `~/.config/kaizen/niri.kdl`.

Without the NixOS module:

- There is no lock screen or curtain: both refuse to start without the
  `kaizen-lock` PAM service.
- Screen recording asks for root through `pkexec` each time it starts, unless
  the host sets `programs.gpu-screen-recorder.enable`.
- Notifications are silent unless the host installs `sound-theme-freedesktop`.
- The network, Bluetooth and battery panels show what the host's
  NetworkManager, BlueZ and UPower provide.

## Install

Requirements the module leaves to you: `hardware.graphics.enable`,
NetworkManager (`networking.networkmanager.enable`) and BlueZ
(`hardware.bluetooth.enable`).

Add the flake and enable the module:

```nix
{
  inputs.kaizen = {
    url = "github:fredrikaverpil/dotfiles?dir=kaizen";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { nixpkgs, kaizen, ... }:
    {
      nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
        modules = [
          ./configuration.nix
          kaizen.nixosModules.default
          { programs.kaizen.enable = true; }
        ];
      };
    };
}
```

The module turns on uwsm, niri, Xwayland, PipeWire, UPower and
power-profiles-daemon (`mkDefault`, it conflicts with TLP and tuned). It also
installs the `kaizen-lock` PAM service and the shell and pre-suspend lock user
units. The package is built with your nixpkgs.

Then include kaizen's niri files at the top of `~/.config/niri/config.kdl`:

```kdl
// Required: uwsm finalize, the wallpaper layer, the recording camera, cursor
// and border.
include "/etc/kaizen/niri/kaizen.kdl"
// Optional: the shell's binds (launcher, lock, notifications, media keys,
// capture).
include "/etc/kaizen/niri/kaizen-binds.kdl"

// Your settings and binds follow and override the above.
```

niri merges most sections, and a chord bound again later replaces the earlier
bind. niri has no unbind, so leave out `kaizen-binds.kdl` to drop its binds.
Starting from niri's default config, delete its `spawn-at-startup "waybar"`,
its `Super+Alt+L` (swaylock) and its XF86 media, volume and brightness binds;
otherwise they override kaizen's. A catch-all window rule of your own (such as
`geometry-corner-radius`) also overrides the recording camera's circle.

Log in on a console and type `kaizen`. The shell starts with the uwsm session
only, not with a display manager's niri session.

## Options

All under `programs.kaizen`; the descriptions in
[`nix/module.nix`](nix/module.nix) have the details.

| Option | Default | |
| --- | --- | --- |
| `enable` | `false` | |
| `package` | built from this flake's source | |
| `theme.dark`, `theme.light` | zenbones | Colours by role, see below |
| `font` | JetBrainsMono Nerd Font | Used when installed |
| `plugins` | `[ ]` | Plugin directories, see below |
| `notificationRules` | `[ ]` | Raise, deduplicate or re-icon notifications |

## Theming

Each theme has eight roles, each `#RRGGBB`. Unset roles keep zenbones.

| Role | Used for |
| --- | --- |
| `bg` | Background |
| `fg` | Text and icons |
| `sel` | Selected and focused rows |
| `dim` | Borders, dividers and tracks |
| `off` | Secondary and inactive text |
| `alert` | Errors, critical notifications and muted devices |
| `warn` | Low battery |
| `accent` | niri's active window border |

```nix
programs.kaizen.theme.dark = {
  bg = "#1E1E2E";
  accent = "#89B4FA";
};
```

The shell follows GNOME's `color-scheme` setting and writes it when switched
(Settings › Display › Theme in the launcher, or
`qs -c kaizen ipc call theme toggle`).

With [Stylix](https://github.com/nix-community/stylix), map its base16 scheme
onto the variant that matches `stylix.polarity`:

```nix
programs.kaizen.theme.dark =
  let
    c = config.lib.stylix.colors.withHashtag;
  in
  {
    bg = c.base00;
    sel = c.base02;
    dim = c.base03;
    off = c.base04;
    fg = c.base05;
    alert = c.base08;
    warn = c.base0A;
    accent = c.base0D;
  };
```

## Plugins

kaizen bundles no plugins. A plugin is a directory holding a `Plugin.qml` whose
root is `Ui.Plugin` ([`shell/Ui/Plugin.qml`](shell/Ui/Plugin.qml)):

- `name` (required): its launcher node is `settings.<name>`, which a
  right-click on its bar buttons opens.
- `menuItems`: launcher items keyed by dotted id, merged into the launcher's.
  An item has `icon`, `label` and optionally `action`, or `provider`, the name
  of a function in `providers` that returns a level's rows.
- `providers`: row functions, merged into the launcher's.
- `barButton`: a `Ui.BarButton` component, placed in the bar on every output.
- `barActions`: core bar buttons it takes over, each mapped to the function
  its left-click calls; the button keeps its label. Names: `date`, `time`,
  `weather`, `notifications`, `clipboard`, `battery`, `network`, `bluetooth`,
  `display`, `audio`. A later plugin wins. The date is a plain label until a
  plugin takes it over.
- `shell` is set by kaizen; pass it to `Ui.BarButton` and `Ui.Panel`.

A plugin creates its own panels (`Ui.Panel`) and `IpcHandler`s, as the core
does.

```qml
import QtQuick
import Quickshell

import qs.Ui as Ui

Ui.Plugin {
  id: plugin

  name: "hello"
  menuItems: ({
    "settings.hello": { icon: "👋", label: "Hello" },
    "settings.hello.say": {
      icon: "👋", label: "Say hello", action: () => plugin.say(),
    },
  })
  barButton: Component {
    Ui.BarButton {
      shell: plugin.shell
      label: "👋"
      onActivated: plugin.say()
    }
  }

  function say(): void {
    Quickshell.execDetached(["notify-send", "Hello"])
  }
}
```

List plugins in load order:

```nix
programs.kaizen.plugins = [
  ./hello # copied to the store
  "/home/me/src/kaizen-weather" # read in place
];
```

Quickshell does not watch plugin files. For a plugin read in place, apply an
edit with `qs -c kaizen ipc call shell reload`.

This repository's
[calendar plugin](../nix/shared/system/kaizen/calendar/) is a complete
example: it takes over the date button and adds launcher items, a panel, a
service and IPC, with the calendar daemon it reads set up in its
`default.nix`.

## Further reading

- [`KAIZEN.md`](KAIZEN.md): design intent, layers, services and where the shell
  writes.
- [`CLAUDE.md`](CLAUDE.md): development, checks and deployment.
  `nix develop ./kaizen` provides `qml-lint`, `qml-test` and
  `compositor-test`. A `~/.config/quickshell/kaizen` link to a checkout's
  `kaizen/shell` takes precedence over the installed tree and reloads on
  save.
