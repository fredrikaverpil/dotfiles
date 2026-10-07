# kaizen features

Description of kaizen features and the rationale behind them.

Most features can be driven from the launcher or the terminal through
Quickshell's IPC (inter-process communication):

```sh
# show all ipc target functions
qs ipc show

# show ipc calls for a given target
kaizen-ipc <target>

# call a target's ipc function
qs ipc call <target> <function> [args...]
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

Notifications arriving via the D-Bus can be transformed by
`host.notificationRules`, keyed by regexes on the notification's data. This
offers capabilities such as restyling, adding action buttons or deduplication.
The features available are described in
[`session.nix`](../../nix/shared/system/kaizen/session.nix).

Rules match only on what the app sends. Capture a real notification first:
[`development.md`](development.md) › Gotchas.

Rules can be specified in the core kaizen system, per-host or by an optional
plugin.

A plugin adds rules from its Nix module, such as a button that runs its own
command with the notification in `NOTIFICATION_APP`, `NOTIFICATION_SUMMARY` and
`NOTIFICATION_BODY`; the
[incident investigator](../../nix/shared/system/kaizen/plugins/incident-investigator/README.md)
does.

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

Niri comes with built-in screenshotting mapped to `Print`. But often you need to
send your screenshot to a lightweight editor
([Satty][https://github.com/gabm/Satty]). In such cases, there's a custom
screenshotting utility available that supports desktop, window or region:
`Shift+Print` for a region, or Trigger › Screenshot.

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
