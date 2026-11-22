# kaizen plugins

A plugin is an optional shell extension: the shell always runs without it,
regardless of how many hosts enable it. See [`README.md`](../README.md) › Where
it lives for where plugin QML and Nix modules live and which hosts they reach.

## Writing one

- **Capabilities:** A plugin
  ([`Ui/Plugin.qml`](../stow/.config/quickshell/kaizen/Ui/Plugin.qml)) can add
  launcher items, panels, and IPC targets. It can also claim the bar's date
  button (`barActions.date`) or display a bar indicator (`barIndicator`):
  left-click triggers the plugin's action, and right-click opens its
  `plugins.<name>` launcher node. Unlike core indicators, a plugin controls
  when its indicator is visible. See
  [`stow/host/renoir/.config/kaizen/plugins/hello/`](../../stow/host/renoir/.config/kaizen/plugins/hello/)
  for a minimal example, and
  [`plugins/gcloud-auth/`](../stow/.config/quickshell/kaizen/plugins/gcloud-auth/)
  for an indicator that always reflects login state.
- **Discovery and config:** For each `~/.config/kaizen/plugins/<name>.jsonc`
  file (in alphabetical order), the shell loads `plugins/<name>/Plugin.qml` if
  its manifest is valid, and reacts when config files are added or removed. The
  JSONC file holds the plugin's configuration (`{}` if none is needed), exposed
  to the plugin as `config` and updated live on save. Generic plugins live
  under `plugins/<name>/` in the shell tree; host-specific plugins live under
  `~/.config/kaizen/plugins/<name>/`. Having the same plugin name in both
  places—or in neither—prevents it from loading. Both locations can
  `import qs.Ui`, which resolves to the shell tree's `Ui/`.
- **Manifest:** Each plugin requires a `plugins/<name>/plugin.json` manifest:

  ```json
  {
    "id": "calendar",
    "name": "Calendar",
    "version": "0.1.0",
    "api": 1,
    "units": ["kaizen-dcal.service"]
  }
  ```

  The shell loads the plugin only if `id` matches its directory name and `api`
  matches the shell tree's
  [`plugin-api`](../stow/.config/quickshell/kaizen/plugin-api) version (bumped
  whenever a breaking change is made to `Ui.Plugin`), passing `id` as the
  plugin's `name`. `units` lists the plugin's systemd user units (each named
  `kaizen-…`), while `name` and `version` label findings in `kaizen doctor`.
  `doctor` flags missing or mismatched manifests and any listed unit that is
  not loaded or not running.
- **Nix packages:** If a plugin needs packages, add a `default.nix` module in
  its directory and import it on the host alongside the core kaizen module.
- **Requirements:** Declare any extra programs, D-Bus services, or files the
  plugin needs beyond core in `plugins/<name>/requires`, using the same format
  as core's [`requires`](../stow/.config/quickshell/kaizen/requires). Where the
  plugin is enabled, `kaizen doctor` reports missing requirements, Nix host
  builds fail if a `cmd`, `file`, or `data` requirement is not installed, and
  `requires-check` fails if plugin QML, JS, or units invoke an undeclared
  program.
- **Systemd user units:** Place plugin units under Stow and enable them with a
  symlink in `kaizen-session.target.wants/` (or
  `kaizen-session-xdg-autostart.target.wants/` for tray apps; see below).
  Generic plugin units live in
  [`kaizen/stow/.config/systemd/user/`](../stow/.config/systemd/user/) with
  `ConditionPathExists=%h/.config/kaizen/plugins/<name>.jsonc` so they only run
  where enabled; host-only units live in `stow/host/<host>/`.
- **Notification rules:** A host's notification rules can add buttons that
  invoke a plugin's commands on another app's notifications (see
  [`features.md`](features.md) › Notifications › Rules).
- **Process model and daemons:** Plugins run in-process inside the shell as
  QML/JS. Introduce a separate process only for a tray icon or long-running
  work that must survive shell reloads. In that case, the plugin's Nix module
  installs the daemon, its systemd unit runs it, and its QML talks to the
  daemon over IPC. Examples:
  - [`kaizen/nix/plugins/calendar/`](../nix/plugins/calendar/) runs [dcal].
  - [`kaizen/nix/plugins/incident-investigator/`](../nix/plugins/incident-investigator/)
    ships a dedicated daemon and reads per-host settings from its plugin JSONC
    file.
- **Logging:** Plugin daemons and tray apps should log background warnings and
  errors with a systemd journal priority—either via syslog prefixes on each
  line (such as `<4>`, as the investigator's `journal.go` writes for `slog`) or
  via `sd_journal`—so `kaizen doctor` surfaces them reliably. Plain text levels
  (`level=WARN`) rely on fallback heuristics in `doctor`, and Go's standard
  `log` package emits neither.
- **Storage:** Plugins and their custom daemons must write only under
  `plugins/<name>/` inside the shell's state and cache roots (`Ui.Paths.state`
  or `Ui.Paths.cache` + `"/plugins/<name>"`, or `StateDirectory=` /
  `CacheDirectory=kaizen-shell/plugins/<name>` in the daemon unit), and name
  runtime files `$XDG_RUNTIME_DIR/kaizen-<name>…`. The rules in
  [`README.md`](../README.md) › Where the shell writes apply (including cache
  pruning). Third-party daemons such as `dcal` keep their own paths.
- **Tray plugins:** A tray plugin is an app built for kaizen with its own
  [StatusNotifierItem] and menu (see
  [`nix/hosts/renoir/kaizen-plugins/hello-tray/`](../../nix/hosts/renoir/kaizen-plugins/hello-tray/)),
  appearing in the bar tray and launcher Tray level without extra shell code.
  Launch it from Apps, or autostart it with a symlink in
  `kaizen-session-xdg-autostart.target.wants/` ordered after
  `kaizen-tray-ready.service` so the tray watcher is ready before registration.
  Third-party apps with tray icons are not plugins—the tray displays them
  automatically.

## Developing one

Quickshell only watches files imported by `shell.qml`, not plugins. Apply
plugin edits with `kaizen reload`, which also prints any QML errors. `qml-lint`
and `qml-format` check all plugins, including host plugins under
`stow/host/*/.config/kaizen/plugins/`; `qml-test` runs `tst_*.qml` tests in the
shell tree's `plugins/` directory. A tray plugin's user unit starts with the
session once enabled via a `.wants/` symlink.

[dcal]: https://github.com/duxlabs-dev/dux-calendar
[StatusNotifierItem]: https://www.freedesktop.org/wiki/Specifications/StatusNotifierItem/
