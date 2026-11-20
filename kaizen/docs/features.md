# kaizen features

Overview of kaizen's features and the rationale behind them.

Most features can be driven from the launcher or a terminal through
Quickshell's IPC:

```sh
# list all IPC targets and their functions
kaizen ipc show

# list IPC functions for a specific target
kaizen ipc show <target>

# call a target's IPC function
kaizen ipc call <target> <function> [args...]

# same, silent and exit 0 if the shell is down or the call fails
kaizen ipc -q call <target> <function> [args...]
```

Each section below names its IPC target in parentheses (for example, Curtain
uses `curtain`).

## Breaks (`breaks`)

A plugin inspired by [Pandan](https://sindresorhus.com/pandan). It displays how
long you have been at the computer without a break and reminds you to take one.

A session ends after `idleMinutes` (default: 5) without input, or when the
screen locks or the curtain goes up. Active idle inhibitors (such as a video
call) keep the session running. The next input starts a new session.

Configure `idleMinutes` and `reminders` in
`~/.config/kaizen/plugins/breaks.jsonc`:

- Each entry in `reminders` fires every `everyMinutes` of a session, displaying
  a large card centered on every output (like the hourly clock). The card shows
  its `icon` (a glyph, defaulting to a coffee cup) above its `title` and either
  its `detail` or the next entry rotating through `details`.
- If `seconds` is set, the card stays up and counts down. Clicking the card or
  running `kaizen ipc call breaks dismiss` dismisses it and stops the
  countdown.
- If `reminders` is omitted, two defaults apply: look into the distance for
  20 seconds every 20 minutes (the 20-20-20 rule), and stand up and move every
  30 minutes.

When multiple reminders come due at the same time, only the one with the
longest interval is shown. Once the longest-interval reminder has fired, the
bar timer switches to `wood`. Left-clicking the bar item shows the session time
large; its menu offers **New session** and **Hold reminders**.

State persists across shell restarts in
`~/.local/state/kaizen-shell/plugins/breaks/state.json` (both the hold flag and
the current session, unless the shell was down for `idleMinutes` or longer).

### Hold

Holding reminders skips them while the session timer keeps counting. When the
hold ends, reminders resume on their normal intervals without catching up on
missed ones.

Toggle the hold via **Plugins › Breaks › Hold reminders** or
`kaizen ipc call breaks toggleHold` (also `setHold on|off` and `holdState`).
While held, the bar shows a struck-through timer icon (`󰔞`) in `rose`, matching
the held notifications bell.

DnD enables the hold automatically and clears it when DnD ends, unless you had
already enabled the hold beforehand. If you toggle the hold manually while DnD
is active, your manual choice wins and DnD will not clear it afterward.

## Curtain (`curtain`)

When an agent verifies its work by opening and interacting with UI elements,
you can hide that activity behind a "curtain"—an overlay drawn over the desktop
like a screensaver, without real lock security. Pressing any key while the
curtain is active brings up a password prompt.

Enable the curtain from **Settings › Session › Curtain**. `kaizen shot`
temporarily lifts the curtain for screenshots and restores it afterward. The
curtain survives shell reloads, restarts, and crashes until logout. Over IPC,
`close` lifts it and `open` restores it.

Because a real lock would prevent screenshotting, the curtain intentionally
does *not*:

- Act as a real screen lock (no `WlSessionLock`).
- Turn off displays (no DPMS), though it dims the laptop backlight.
- Suspend the machine.
- ⚠️ Lock the machine: idle locking is paused while the curtain is up. Always
  use the real lock when stepping away.

## Do not disturb (`dnd`)

DnD is a shell-wide mode signaling "do not interrupt the screen." Features that
would interrupt read this flag and suppress themselves, so DnD needs no
knowledge of them and automatically covers future features. Currently, DnD:

- Holds notifications in history (see [Notifications › Hold](#hold-1)).
- Holds break reminders while keeping the timer running (see
  [Breaks › Hold](#hold)).
- Suppresses the hourly time overlay (see
  [Time and timezone](#time-and-timezone-timezone)).

Toggle DnD via **Settings › Do not disturb (DnD)** or
`kaizen ipc call dnd toggle` (also `set on|off` and `state`). Its state
survives shell restarts.

Screen recording enables DnD by default, as does any app sharing the screen
through the portal (a PipeWire cast in `niri msg casts`, or the
`umbriel-screen-capture` PipeWire node on umbriel). DnD turns back off when the
last recording or cast ends, unless it was already on beforehand. Toggling DnD
manually in the meantime overrides automatic cleanup, leaving it in the state
you chose.

## Doctor (`doctor`)

`kaizen doctor` reports desktop problems that are otherwise invisible on
screen. A healthy desktop produces no output, so every finding is actionable; a
`hint:` line beneath a finding names the fix when one exists. If a check itself
fails to run, `doctor` reports it as an error and continues running the rest.

`kaizen doctor` checks for:

- Warnings and errors logged by any `kaizen-*` unit (including plugin daemons)
  during its current run.
- Failed units, and restarted units (showing how each failed run exited and its
  last warning or error).
- A running shell still using an old Quickshell binary after a rebuild, or
  running a worktree via `kaizen dev`.
- A `kaizen` binary shadowing another on `PATH`.
- A session with no compositor socket variable set, or more than one.
- A niri config failing `niri validate` or not including `kaizen.kdl`; an
  umbriel config failing `umbriel config validate` or not including
  `kaizen.toml`.
- An XDG portal that does not answer color-scheme queries.
- A `gsr-kms-server` binary missing `cap_sys_admin+ep`.
- An enabled plugin that fails to load or whose units are not running.
- Any program, D-Bus service, file, session variable, font, Qt plugin, or
  Wayland protocol listed in a `requires` file that is missing from the system
  or compositor.

`doctor` ignores errors an application already shows in its own window or
toast, D-Bus calls that fail because the peer left the bus (such as a closed
media player), and keyring errors from mistyped lock or curtain passwords.
Because Quickshell logs a failed D-Bus call's error on a separate line,
`doctor` pairs it with the preceding call line.

Manually restarting a unit clears its current-run log findings. Passing
`journalctl` arguments (such as `kaizen doctor -b -1` or `--since -1h`) scans
that journal range instead of running live checks.

The shell runs `kaizen doctor` once per minute and whenever the Doctor panel
opens. While any finding exists, the bar displays an indicator (`rose` for
errors, `wood` for warnings only). Clicking it opens the Doctor panel, with one
row per finding: pressing `Enter`, `Space`, or clicking copies that finding's
message and hint, and **Copy report** copies the full report.

## Firmware (`firmware`)

The Firmware panel lists pending firmware updates without installing them.
Because installing firmware can require AC power, root privileges, or a reboot,
you run the update command in a terminal. Each update's **Copy update command**
button (and **Settings › Firmware › Copy update command**) copies
`fwupdmgr update <id>`.

Each host decides which firmware backends to run: kaizen queries [fwupd]
whenever it is activatable on the system bus and never enables the daemon
itself. The shell checks local metadata at startup, once per day, and when the
panel opens; `fwupd`'s own timer handles downloading metadata.

Each update's **Open release page** button (and **Settings › Firmware › Open
release page**) opens the vendor's release notes, falling back to the [LVFS]
device page if none is provided.

While updates are pending, the bar shows a `wood` indicator regardless of
urgency, since firmware updates can wait for a convenient reboot. Individual
updates display their own urgency in the panel. Firmware updates never trigger
notifications.

[fwupd]: https://fwupd.org
[LVFS]: https://fwupd.org/lvfs/

## Notifications (`notifications`)

Apps send notifications over D-Bus. You can send one from a shell or script
with [`notify-send`][notify-send], which the shell itself uses for battery,
screenshot, and recording notifications:

```sh
# show a notification
notify-send -a <app> <summary> <body>

# critical: stays until dismissed
notify-send -u critical <summary> <body>

# with buttons; prints the pressed button's id
notify-send -A yes=Yes -A no=No <summary> <body>

# with an icon: a file path, or a name from the icon theme
notify-send -i /path/to/icon.svg <summary> <body>
```

### Rules

Incoming D-Bus notifications can be transformed by rules matched via regexes on
notification fields—allowing restyling, extra action buttons, or deduplication.
See `ruleCheck` in
[`NotificationLogic.js`](../stow/.config/quickshell/kaizen/modules/notifications/NotificationLogic.js)
for the supported fields.

Rules match only against the raw data the app actually sends, so capture a real
notification first (see [`development.md`](development.md) › Gotchas).

Place `*.jsonc` rule lists in either `notification-rules.d/` directory below.
The shell reads files from both directories in filename order and reloads edits
on save. For each setting, a notification takes the value from the first
matching rule that defines it. Relative icon paths resolve against the rule
file's directory. Invalid files or rules are skipped with a warning reported by
`kaizen doctor`.

| File | Under | Holds |
| --- | --- | --- |
| `10-kaizen.jsonc` | `~/.config/quickshell/kaizen/`, from [`kaizen/stow/`](../stow/.config/quickshell/kaizen/notification-rules.d/) | core rules |
| `50-<what>.jsonc` | `~/.config/kaizen/`, from `stow/host/<host>/` or a private submodule's `stow/` | host rules |

A rule's action button can run a plugin command with the notification passed in
`NOTIFICATION_APP`, `NOTIFICATION_SUMMARY`, and `NOTIFICATION_BODY` (used by
the [incident investigator](../nix/plugins/incident-investigator/README.md)).

### Toasts

Activating a toast focuses its app's window. Because apps cannot raise their
own windows without an activation token—and the notification server cannot pass
one along—the shell handles focusing directly. A rule's `focus` field can
redirect focus to a different window than the sender (for example, a Google
Calendar reminder relayed through Slack).

Critical toasts stay on screen until dismissed; all others time out.

### Hold

Holding notifications sends every incoming notification—including critical
ones—straight to the notification history panel instead of showing a toast.
Toggle it via **Settings › Notifications › Hold notifications**, the panel's
**Hold** button, or `kaizen ipc call notifications toggleHold` (also
`setHold on|off` and `holdState`). The bell icon turns `rose` while active, and
blinks if a critical notification has been held back.

DnD enables the hold automatically and clears it when DnD ends, unless you had
already enabled the hold beforehand. If you toggle the hold manually while DnD
is active, your manual choice wins and DnD will not clear it afterward.

### History

The notification history stores only notifications captured while held, ordered
newest first with critical notifications pinned to the top. An app's own action
buttons only work while the app still tracks the live notification, so they are
omitted in history; only buttons added by notification rules remain.

[notify-send]: https://man.archlinux.org/man/notify-send.1

## Recording (`recording`)

### Screenshot

A custom screenshot tool replaces niri's built-in one and can send captures to
[Satty](https://github.com/gabm/Satty) for quick annotation. It supports
region (`Print`), focused screen (`Shift+Print`), and desktop or window
captures (**Trigger › Screenshot**).

### Record screen

The screen recorder captures a desktop, window, or region, with optional audio
controls and a circular camera overlay. Press `Mod+Print` to open the recording
panel (or stop an active recording), and `Mod+Shift+Print` to pause or resume.
Recordings are saved to `~/Videos/Recordings`.

## Time and timezone (`timezone`)

On the hour, the time appears in large text at the center of every output for a
few seconds without stealing keyboard or pointer focus. It is suppressed during
DnD (so it never appears in screen shares or recordings) and while the screen
is locked or curtained. Hours that pass while the machine is asleep are not
shown on resume. Click the overlay to dismiss it, or run
`kaizen ipc call timezone hour` to display it immediately regardless of
suppression.

The rest is to be written.

## Weather and location

To be written.

## Display settings

To be written.

## Audio controls

To be written.

## Media controls

To be written.

## Bluetooth

To be written.

## Wi-Fi and network

To be written.

## Battery

To be written.

## Tray

To be written.

## Plugins

To be written.
