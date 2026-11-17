# kaizen features

Description of kaizen features and the rationale behind them.

Most features can be driven from the launcher or the terminal through
Quickshell's IPC (inter-process communication):

```sh
# show all ipc target functions
kaizen ipc show

# show ipc calls for a given target
kaizen ipc show <target>

# call a target's ipc function
kaizen ipc call <target> <function> [args...]

# same, silent and exit 0 when the shell is down or the call fails
kaizen ipc -q call <target> <function> [args...]
```

The below sections correspond to an IPC target (e.g. Curtain correlates to
target `curtain`).

## Breaks (`breaks`)

A plugin, after [Pandan](https://sindresorhus.com/pandan): breaks shows in the
bar how long you have been at the computer without a break, and reminds you to
take one. A session ends after `idleMinutes` (5) without input, an idle
inhibitor such as a video call's keeping it going, or when the screen locks or
the curtain goes up; the next input starts a new one.

Each reminder in `reminders` comes due every `everyMinutes` of a session, its
`icon` (a glyph, a coffee cup by default) large in the middle of every output,
as the hour is, over its `title` and its `detail`, or the next of its `details`
each time. With `seconds`, the card stays up counting them down. A click on
the card, or `kaizen ipc call breaks dismiss`, dismisses it and ends its count.
Without
`reminders`, two follow the eye and movement guidance: look into the distance
for 20 s every 20 minutes (the 20-20-20 rule), and stand up and move every 30.
Both settings are in `~/.config/kaizen/plugins/breaks.jsonc`.

When several come due together, only the one with the longest interval shows.
The bar shows the time in `wood` once the longest-interval reminder came due.
Its left-click shows the session time large; New session and Hold reminders are
in its menu.

Its state survives a shell restart, in
`~/.local/state/kaizen-shell/plugins/breaks/state.json`: the hold, and the
session, unless the shell was down `idleMinutes` or longer.

### Hold

Holding reminders skips them while the time keeps counting; when the hold ends,
the next one comes due on its interval, with no catch-up. Plugins › Breaks ›
Hold reminders toggles it, as does `kaizen ipc call breaks toggleHold`
(`setHold on|off`, `holdState`). While it holds, the bar shows the time beside
a timer struck through (󰔞) in rose, as the notifications' bell turns.

DnD turns the hold on, and off again when DnD ends, unless it was already on.
Toggling the hold by hand in the meantime wins: then DnD ending leaves it on.

## Curtain (`curtain`)

When the agent verifies its work by invoking UI elements on the screen and
interacting with them, the activity can be hidden by enabling a "curtain". Think
of it as an overlay surface drawn on top of the desktop, like a screensaver of
sorts, but without the proper security features in place. Pressing any key
while the curtain is active will show a password prompt.

The user turns the curtain on from Settings › Session › Curtain in the launcher.
`kaizen shot` lifts it for a screenshot and puts it back. It stays up through a
reload or restart of the shell, a crash included, until logout. Over IPC,
`close` lifts it and `open` puts it back.

What the curtain does not do, since it would stop screenshotting from working:

- It is not a real screen lock (no `WlSessionLock`).
- It never turns the screens off (no DPMS), but it dims the laptop screen's
  backlight.
- It never causes the machine to go to sleep.
- ⚠️ It never locks the machine: idle locking is paused while the curtain is up.
  Always use the real lock when leaving the machine.

## Do not disturb (`dnd`)

DnD is a mode the shell broadcasts: turning it on says "do not interrupt the
screen", and each feature that would interrupt it reads the mode and holds
itself back. DnD knows nothing of them, so it does the same for whatever joins
later. Today:

- Notifications are held back to the history (Notifications › Hold).
- Breaks holds its reminders, while still counting (Breaks › Hold).
- The hour's time does not show (Time and timezone).

Settings › Do not disturb (DnD) toggles it, as does
`kaizen ipc call dnd toggle`; `set on|off` sets it and `state` prints it. It
survives a shell restart.

The screen recording dialog turns it on by default, and so does an app sharing
the screen through the portal (a PipeWire cast in `niri msg casts`, or on
umbriel the portal's `umbriel-screen-capture` PipeWire node). DnD turns off
again when the last of them ends, unless it was already on. Toggling DnD by
hand in the meantime wins: then nothing turns it off afterwards.

## Doctor (`doctor`)

`kaizen doctor` reports what is wrong with the desktop that nothing on screen
shows: the warnings and errors each `kaizen-*` unit, plugin daemons included,
logged in its current run, a failed unit, a restarted unit with how each failed
run exited and the last warning or error it logged, a shell still running the
Quickshell a rebuild replaced or a worktree's tree (`kaizen dev`), a `kaizen`
shadowing another on PATH, a session with no compositor's socket variable or
more than one, a niri config that fails `niri validate` or never
includes `kaizen.kdl`, an umbriel config that fails `umbriel config validate` or
never includes `kaizen.toml`, a portal that does not answer the colour scheme, a
`gsr-kms-server` without `cap_sys_admin+ep`, an enabled plugin the shell cannot
load or whose units are not running, and a program, D-Bus service, file, session
variable, font, Qt plugin or Wayland protocol that a `requires` file lists and
the system or compositor lacks. A
healthy desktop reports nothing, so every finding is something to fix; a `hint:`
line under it names the fix when there is one. A check that cannot run is an
error of `doctor`, and the others still run. An error an application shows in
its window or a toast stays out of it, as does a D-Bus call Quickshell could not
finish because the peer left the bus, such as a closed player's, and the
keyring error a mistyped lock or curtain password logs. Quickshell logs
a failed D-Bus call's error on a line of its own; doctor reports it with the
call's line.

A unit restarted by hand starts clean. With journalctl arguments
(`kaizen doctor -b -1`, `--since -1h`) it reports that span of the journal
instead, without the checks.

The shell runs it every minute and when the panel opens. The bar shows an
indicator while it reports anything: rose with any error, wood for warnings
only. It opens the doctor panel, a row per finding: Enter, Space or a click
copies its message and hint. Copy report copies the whole report.

## Firmware (`firmware`)

The firmware panel lists pending firmware updates; it never installs them.
Installing can need AC power, a reboot, or root, so the user runs the update
command in a terminal. Each update's Copy update command button copies that
command (`fwupdmgr update <id>`), as does Settings › Firmware › Copy update
command.

The host decides which backends run: kaizen reads [fwupd] when the system bus
can activate it, and never enables a backend's daemon. The shell checks at
start, once a day and when the panel opens, reading only local metadata; fwupd's
own timer downloads it.

An update's Open release page button (Settings › Firmware › Open release page)
opens the vendor's details page, or the update's [LVFS] device page when the
vendor sets none.

The bar shows an indicator in wood while an update is pending, whatever its
urgency: an update can wait for a convenient reboot. Each update shows its own
urgency. There are no notifications.

[fwupd]: https://fwupd.org
[LVFS]: https://fwupd.org/lvfs/

## Notifications (`notifications`)

Apps send notifications over D-Bus. [`notify-send`][notify-send] sends one from
a shell or script, as the shell does for its own (battery, screenshots,
recordings):

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

Notifications arriving via the D-Bus can be transformed by notification rules,
keyed by regexes on the notification's data. This offers capabilities such as
restyling, adding action buttons or deduplication. The fields are described at
`ruleCheck` in
[`NotificationLogic.js`](../stow/.config/quickshell/kaizen/modules/notifications/NotificationLogic.js).

Rules match only on what the app sends. Capture a real notification first:
[`development.md`](development.md) › Gotchas.

Each `*.jsonc` in the two `notification-rules.d/` below holds a list of rules in
JSONC (JSON with comments). The shell reads the files of both in file-name order
and applies an edit on save; a notification takes each setting from the first
matching rule that has one. A relative icon path resolves against the file's
directory. A file or rule that is invalid is dropped with a warning, which
`kaizen doctor` lists.

| File | Under | Holds |
| --- | --- | --- |
| `10-kaizen.jsonc` | `~/.config/quickshell/kaizen/`, from [`kaizen/stow/`](../stow/.config/quickshell/kaizen/notification-rules.d/) | the core's rules |
| `50-<what>.jsonc` | `~/.config/kaizen/`, from `stow/host/<host>/` or a private submodule's `stow/` | a host's rules |

A rule's button may run a plugin's command, with the notification in
`NOTIFICATION_APP`, `NOTIFICATION_SUMMARY` and `NOTIFICATION_BODY`; the
[incident investigator](../nix/plugins/incident-investigator/README.md)
has one.

### Toasts

Activating a toast focuses its app's window. Apps cannot raise their own window
without an activation token, which the server has no way to pass on, so the
shell does it. A rule's `focus` picks the window when it is not the sender's,
such as a reminder Slack relays for Google Calendar.

Critical toasts stay until dismissed. Others will timeout and disappear.

### Hold

Holding notifications sends every one, critical ones included, to the
notification history panel instead of a toast: Settings › Notifications › Hold
notifications, the panel's Hold button, or
`kaizen ipc call notifications toggleHold` (`setHold on|off`, `holdState`).
The bell turns rose while it holds.

DnD turns the hold on, and off again when DnD ends, unless it was already on.
Toggling the hold by hand in the meantime wins: then DnD ending leaves it on.

The bell blinks while the hold has held back a critical notification.

### History

The history holds only what the hold held back, newest first with critical ones
always at the top. Some action buttons will not appear on the notifications in
the history, due to how an app's own buttons only work while the app still holds
the notification. Only buttons added via notification rules are retained in the
history.

[notify-send]: https://man.archlinux.org/man/notify-send.1

## Recording (`recording`)

### Screenshot

A custom screenshotting utility replaces niri's built-in one and offers to send
the screenshot to a lightweight editor ([Satty][https://github.com/gabm/Satty]).
It supports desktop, window or region: `Print` for a region, `Shift+Print` for
the focused screen, or Trigger › Screenshot.

### Record screen

A screen recording utility makes it possible to record the screen (desktop,
window or region) along with showing a circular video feed captured from a
camera. Audio controls are available. `Mod+Print` opens the recording panel or
stops a running recording; `Mod+Shift+Print` pauses or resumes it. Recordings
are saved to `~/Videos/Recordings`.

## Time and timezone (`timezone`)

On the hour, the time shows large in the middle of every output for a few
seconds, impossible to miss without taking the keyboard or the pointer. It is
held back under DnD, so it never lands in a screen share or a recording, and
while the screen is locked or curtained; an hour struck asleep is not shown on
resume. A click on it dismisses it. `kaizen ipc call timezone hour` shows it
now, whatever holds it back.

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
