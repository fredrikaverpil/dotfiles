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
```

The below sections correspond to an IPC target (e.g. Curtain correlates to
target `curtain`).

## Curtain (`curtain`)

When the agent verifies its work by invoking UI elements on the screen and
interacting with them, the activity can be hidden by enabling a "curtain". Think
of it as an overlay surface drawn on top of the desktop, like a screensaver of
sorts, but without the proper security features in place. Pressing any key
while the curtain is active will show a password prompt.

The user turns the curtain on from Settings › Session › Curtain in the launcher.
When the agent needs to take a screenshot, it lifts the curtain with `close` and
puts it back with `open`.

What the curtain does not do, since it would stop screenshotting from working:

- It is not a real screen lock (no `WlSessionLock`).
- It never turns the screens off (no DPMS), but it dims the laptop screen's
  backlight.
- It never causes the machine to go to sleep.
- ⚠️ It never locks the machine: idle locking is paused while the curtain is up.
  Always use the real lock when leaving the machine.

## Firmware (`firmware`)

The firmware panel lists pending firmware updates; it never installs them.
Installing can need AC power, a reboot, or root, so the user runs the update
command in a terminal. Each update's row copies that command (`fwupdmgr update
<id>`) with Enter, Space or a click, as does Settings › Firmware › Copy update
command.

The host decides which backends run: kaizen reads [fwupd] when the system bus
can activate it, and never enables a backend's daemon. The shell checks at
start, once a day and when the panel opens, reading only local metadata; fwupd's
own timer downloads it.

`O` on a row, or Settings › Firmware › Open release page, opens the vendor's
details page, or the update's [LVFS] device page when the vendor sets none.

The bar shows an indicator in wood while an update is pending, whatever its
urgency: an update can wait for a convenient reboot. Each row shows its own
urgency. There are no notifications.

[fwupd]: https://fwupd.org
[LVFS]: https://fwupd.org/lvfs/

## Log (`log`)

`kaizen log` lists the warnings and errors that the `kaizen-*` units, plugin
daemons included, logged this boot. A healthy desktop logs none, so every
entry is something to fix. It holds what nothing on screen shows: an error an
application shows in its window or a toast stays out of it.

The bar shows an indicator while it lists anything: rose when an error is among
the entries, wood for warnings only. It opens the log panel, newest entry
first; Enter, Space or a click copies an entry's line, and Copy all copies
every entry the panel holds (the latest 200). The indicator stays until the
next boot, since the journal keeps what earlier shell instances logged.

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
[`NotificationLogic.js`](../../stow/kaizen/.config/quickshell/kaizen/modules/notifications/NotificationLogic.js).

Rules match only on what the app sends. Capture a real notification first:
[`development.md`](development.md) › Gotchas.

Each `*.jsonc` in the two `notification-rules.d/` below holds a list of rules in
JSONC (JSON with comments). The shell reads the files of both in file-name order
and applies an edit on save; a notification takes each setting from the first
matching rule that has one. A relative icon path resolves against the file's
directory. A file or rule that is invalid is dropped with a warning, which
`kaizen log` lists.

| File | Under | Holds |
| --- | --- | --- |
| `10-kaizen.jsonc` | `~/.config/quickshell/kaizen/`, from [`stow/kaizen/`](../../stow/kaizen/.config/quickshell/kaizen/notification-rules.d/) | the core's rules |
| `50-<what>.jsonc` | `~/.config/kaizen/`, from `stow/host/<host>/` or a private submodule's `stow/` | a host's rules |

A rule's button may run a plugin's command, with the notification in
`NOTIFICATION_APP`, `NOTIFICATION_SUMMARY` and `NOTIFICATION_BODY`; the
[incident investigator](../../nix/shared/system/kaizen/plugins/incident-investigator/README.md)
has one.

### Toasts

Activating a toast focuses its app's window. Apps cannot raise their own window
without an activation token, which the server has no way to pass on, so the
shell does it. A rule's `focus` picks the window when it is not the sender's,
such as a reminder Slack relays for Google Calendar.

Critical toasts stay until dismissed. Others will timeout and disappear.

### Do not disturb (DnD)

DnD is for sharing the screen or recording it, so it holds back
every notification, critical ones included, to the notification history panel.

The status bar's bell icon blinks when critical notifications arrive or when DnD
has been active for a longer time.

The screen recording dialog turns it on by default, and so does an app sharing
the screen through the portal (a PipeWire cast in `niri msg casts`). DnD turns
off again when the last of them ends, unless it was already on. Toggling DnD by
hand in the meantime wins: then nothing turns it off afterwards.

### History

The history holds only what DnD held back, newest first with critical ones
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
stops a running recording; `Mod+Shift+Print` pauses or resumes it.

## Time and timezone

To be written.

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
