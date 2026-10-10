# kaizen plugins

A plugin is an optional shell extension: the shell runs without it, however
many hosts import it. Where its Nix module and QML live, and which hosts it
reaches, is in [`README.md`](README.md) › Where it lives.

## Writing one

- A plugin
  ([`Ui/Plugin.qml`](../../stow/kaizen/.config/quickshell/Ui/Plugin.qml)) adds
  launcher items, its own panels and IPC targets, and may take over the date
  button (`barActions.date`) or show an indicator (`barIndicator`): left-click
  calls the plugin, right-click opens its `plugins.<name>` node. Unlike the core
  indicators, the plugin picks when it shows.
  [`nix/hosts/renoir/kaizen-plugins/hello/`](../../nix/hosts/renoir/kaizen-plugins/hello/)
  is the minimal example;
  [`nix/shared/system/kaizen/plugins/gcloud-auth/`](../../nix/shared/system/kaizen/plugins/gcloud-auth/)
  always shows its login state as one.
- Its Nix module is a home-manager module, `home.nix`, holding its `kaizen.*`
  settings, units and packages, so it runs wherever the core's `home.nix` does.
  `default.nix` is what a host imports: it adds `home.nix` to the host's
  home-manager users, and holds any part that needs NixOS.
- Its Nix module may add notification rules, such as buttons on another app's
  notifications: [`features.md`](features.md) › Notifications › Rules.
- Plugin code runs in the shell as QML/JS. It needs a process of its own only
  for a tray item or for work that must outlive a shell reload, as below.
- A plugin that needs a long-running backend brings its own daemon: its module
  adds the unit, and its QML queries the daemon's IPC. The calendar
  ([`nix/shared/system/kaizen/plugins/calendar/`](../../nix/shared/system/kaizen/plugins/calendar/))
  does this with [dcal]. The incident investigator
  ([`nix/shared/system/kaizen/plugins/incident-investigator/`](../../nix/shared/system/kaizen/plugins/incident-investigator/))
  brings a daemon written for it, and takes what differs per host from its
  module's options.
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
  it with the session or from Apps. A third-party app with a tray icon is not a
  plugin; the tray shows it anyway.

## Developing one

- Quickshell does not watch plugins: apply an edit with
  `qs ipc call shell reload`. `qml-test` runs the calendar's, gcloud-auth's and
  the incident investigator's tests; `qml-lint` skips plugins (their
  `import qs.Ui` resolves only inside Quickshell). A tray plugin's user unit
  starts with the session when its module sets `autostart`.

[dcal]: https://github.com/AvengeMedia/dankcalendar
[StatusNotifierItem]: https://www.freedesktop.org/wiki/Specifications/StatusNotifierItem/
