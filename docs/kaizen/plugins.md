# kaizen plugins

A plugin is an optional shell extension: the shell runs without it, however
many hosts enable it. Where its QML and Nix module live, and which hosts it
reaches, is in [`README.md`](README.md) › Where it lives.

## Writing one

- A plugin
  ([`Ui/Plugin.qml`](../../stow/kaizen/.config/quickshell/kaizen/Ui/Plugin.qml))
  adds launcher items, its own panels and IPC targets, and may take over the
  date button (`barActions.date`) or show an indicator (`barIndicator`):
  left-click calls the plugin, right-click opens its `plugins.<name>` node.
  Unlike the core indicators, the plugin picks when it shows.
  [`stow/host/renoir/.config/kaizen/plugins/hello/`](../../stow/host/renoir/.config/kaizen/plugins/hello/)
  is the minimal example;
  [`plugins/gcloud-auth/`](../../stow/kaizen/.config/quickshell/kaizen/plugins/gcloud-auth/)
  always shows its login state as one.
- The shell loads `plugins/<name>/Plugin.qml` for each
  `~/.config/kaizen/plugins/<name>.jsonc`, in name order, and picks up a file
  added or removed. The file holds the plugin's config in JSONC, `{}` when it
  has none. A generic plugin's `plugins/<name>/` is in the shell tree, a host's
  in `~/.config/kaizen/`; a name in both, or in neither, does not load. Plugin
  QML imports `qs.Ui`, which resolves to the shell tree's `Ui/` from either.
- A plugin that needs a package has a Nix module, its directory's
  `default.nix`, which a host imports beside the core's.
- A plugin's unit is a file under Stow, enabled by a link in
  `wayland-session@niri.target.wants/`, or in the autostart target's when it
  shows a tray item (below). A generic plugin's lives in
  [`stow/kaizen/`](../../stow/kaizen/.config/systemd/user/) with
  `ConditionPathExists=%h/.config/kaizen/plugins/<name>.jsonc`, so it runs only
  where the plugin is enabled; a host-only one in `stow/host/<host>/`.
- A host's notification rules may add buttons that run the plugin's commands
  on another app's notifications: [`features.md`](features.md) ›
  Notifications › Rules.
- Plugin code runs in the shell as QML/JS. It needs a process of its own only
  for a tray item or for work that must outlive a shell reload, as below.
- A plugin that needs a long-running backend brings its own daemon: its module
  installs it, its unit runs it, and its QML queries the daemon's IPC. The
  calendar
  ([`nix/shared/system/kaizen/plugins/calendar/`](../../nix/shared/system/kaizen/plugins/calendar/))
  does this with [dcal]. The incident investigator
  ([`nix/shared/system/kaizen/plugins/incident-investigator/`](../../nix/shared/system/kaizen/plugins/incident-investigator/))
  brings a daemon written for it, and takes what differs per host from its
  plugin file.
- A plugin's daemon or tray app logs what nothing on screen shows with a
  logger that writes the level, such as Go's slog (`level=WARN`), so that
  `kaizen log` lists its warnings and errors. Go's `log` writes none.
- A plugin, and a daemon written for it, writes only under `plugins/<name>/` in
  the shell's state and cache roots (`Ui.Paths.state` or `Ui.Paths.cache` +
  `"/plugins/<name>"`; a daemon's unit sets `StateDirectory` or
  `CacheDirectory = "kaizen-shell/plugins/<name>"`), and names its runtime files
  `$XDG_RUNTIME_DIR/kaizen-<name>…`. The rules of [`README.md`](README.md) ›
  Where the shell writes apply: a cache producer prunes its own entries. A
  third-party daemon a plugin queries, such as dcal, keeps its own paths.
- A tray plugin is an app written for kaizen, with its own [StatusNotifierItem]
  and menu
  ([`nix/hosts/renoir/kaizen-plugins/hello-tray/`](../../nix/hosts/renoir/kaizen-plugins/hello-tray/)),
  so the tray and its launcher level show it without shell code. Its unit starts
  it from Apps, or with the XDG autostart apps through a link in
  `wayland-session-xdg-autostart@niri.target.wants/`, ordered after
  `kaizen-tray-ready.service` so the tray is up when it registers. A plugin's
  daemon that shows a tray item, as the investigator's does, starts the same
  way. A third-party app with a tray icon is not a plugin; the tray shows it
  anyway.

## Developing one

- Quickshell watches only the files `shell.qml` imports, not plugins: apply an
  edit with `kaizen ipc call shell reload`. `qml-lint` and `qml-format`
  cover every plugin, a host's in `stow/host/*/.config/kaizen/plugins/`
  included; `qml-test` runs the `tst_*.qml` in the shell tree's `plugins/`. A
  tray plugin's user unit starts with the session when a `.wants/` link
  enables it.

[dcal]: https://github.com/AvengeMedia/dankcalendar
[StatusNotifierItem]: https://www.freedesktop.org/wiki/Specifications/StatusNotifierItem/
