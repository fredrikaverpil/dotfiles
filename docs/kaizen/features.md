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

## Notification rules (`notifications`)

Notifications arriving via the D-Bus can be transformed by
`host.notificationRules`, keyed by regexes on the notification's data. This
offers capabilities such as restyling, adding action buttons or deduplication.
The features available are described in
[`session.nix`](../../nix/shared/system/kaizen/session.nix).

Rules match only on what the app sends. Capture a real notification first:
[`development.md`](development.md) › Gotchas.

Rules can be specified in the core kaizen system, per-host or by an optional
plugin.

## Do not disturb (`notifications`)

Do not disturb is for sharing the screen or recording it, so it holds back
every notification, critical ones included. Held-back notifications go to the
history, sorted newest first, with critical ones always at the top.

So it is not forgotten on, the bar's bell blinks once it has been on for 10
minutes; opening the notifications panel snoozes that for another 10. It blinks
fast while the history holds a critical notification it held back, until those
are cleared. The start time is saved, so a shell restart keeps the clock.

The recording dialog turns it on by default, and turns it off again when the
recording ends or is cancelled, unless it was already on.

## Recording

- The camera is a circle because gpu-screen-recorder cannot mask its own
  camera overlay: the service runs mpv under the `kaizen-camera` app id and a
  niri window rule rounds and places it, so the screen capture records it as
  ordinary screen content. It must therefore sit inside a recorded region.
- Its diameter is a share of the captured frame's short side, so it covers the
  same part of the recording on a region as on an output of any resolution.
  The window rule's corner is the output's, which a region rarely reaches, so a
  region's circle is moved into the region's own bottom-right.
- The circle's scale and coordinates belong to the output it opened on, which
  is whichever one had focus, so starting a recording *with a camera* focuses
  the output being captured. Recording without one never moves focus.
- mpv sizes in device pixels, which is why the service asks niri for the
  focused output's scale instead of using Qt's rounded `devicePixelRatio`. niri
  has neither an aspect-ratio rule nor sticky windows, and mpv accepts any size
  it is given, so while the preview is up the service follows the event
  stream: it sets the window's height back to its width and moves it to each
  workspace that gains focus. `move-floating-window` takes coordinates in the
  output's working area, which the bar shortens at the top, and reads a bare
  negative number as a relative move.
- The recording service also owns the region screenshot (`grim`), because that
  reuses its region selector; `selectMode` says which of the two the selection
  feeds. Niri's own `screenshot` binds are unrelated and stay compositor-side.

## Time and place

- The timezone lives in [timedated] (`/etc/localtime`). The timezone service
  runs `timedatectl set-timezone` with an id from
  [`ZonesModel.js`](../../stow/kaizen/.config/quickshell/modules/services/timezone/ZonesModel.js)
  and reads the result back; polkit may prompt. ThinkPads leave `time.timeZone`
  unset so the choice survives rebuilds; stationary hosts pin it.
- Zones are IANA ids. tzdata evaluates DST per instant; the Clock panel shows
  offset, abbreviation, UTC and the next DST change, the last from `zdump`.
- Zone-aware formatting goes through `date(1)`. Qt's JS engine has no `Intl`
  and ignores `toLocaleString`'s `timeZone` option.
- The weather location is a coordinate picked from
  [`PlacesModel.js`](../../stow/kaizen/.config/quickshell/modules/services/weather/PlacesModel.js)
  and saved by the shell; the machines have no GNSS. Nightlight takes sunrise
  and sunset from the same coordinate, so one saved place moves both.
- After a zone change, restart `quickshell.service` by hand, and any other
  long-running process that shows local time, such as the calendar plugin's
  `dcal.service`: glibc caches the parsed tzfile, so a running process keeps
  the zone it started with. The restart stays manual because the shell must
  never restart while locked. Removing `/etc/localtime` is not a test; that
  falls back to UTC, which only looks like a live pickup.

[timedated]: https://www.freedesktop.org/software/systemd/man/latest/org.freedesktop.timedate1.html
