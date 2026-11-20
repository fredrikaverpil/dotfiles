# kaizen style

Visual design rules for the shell. For architecture and file locations, see
[`README.md`](../README.md).

## Palette

kaizen uses the dark and light variants of
[zenbones](https://github.com/zenbones-theme/zenbones.nvim), defined once in
[`Ui/Palette.js`](../stow/.config/quickshell/kaizen/Ui/Palette.js) and switched
by the theme toggle in
[`shell.qml`](../stow/.config/quickshell/kaizen/shell.qml). QML must always read
colors from `shell.palette`, never hex literals. Core follows these color roles
strictly; plugins start from them and may deviate when needed.

| Role | Meaning |
| --- | --- |
| `bg`, `fg` | Surface, text, focused outline |
| `dim` | Unfocused outline, card border |
| `sel` | Hover, focus, and selection fill |
| `off` | Secondary text, hints, unavailable, cancelled, logged out |
| `rose` | Needs attention: error, failure, disabled core feature, live activity (recording, idle inhibited), production |
| `wood` | Warning, draft |
| `leaf` | Success, done, connected, logged in |
| `sky` | Running, in progress |
| `water` | Accent and information: links, inline code, active window border, neutral tags |
| `blossom` | Headings in rendered Markdown |

## Shapes and text

- **Buttons and inputs:** 1 px outline with 4 px radius—`fg` when focused,
  `dim` otherwise—and `sel` fill on focus or hover. Panel buttons are an
  exception (see [Panels › Focus and state](#focus-and-state)). List rows show
  focus with `sel` fill alone. Failed inputs (lock screen, polkit) turn their
  outline `rose`. The lock password field and selections drawn over content use
  a 2 px outline.
- **Surfaces:** Panels, context menus, notifications, and OSDs use an 8 px
  corner radius.
- **Keycaps:** Keyboard shortcuts render as individual keycaps (`Super`
  `Space`), separated from their label: 12 px `off` text inside a `dim`
  outline with 3 px radius and a 2 px bottom edge. In menu rows, keycaps sit in
  a right-hand column.
- **Typography and Markdown:** Body text uses `Ui.Fonts.mono` at 14 px, scaled
  by the text scale. Keycaps and panel footers are 12 px (see
  [Panels › Type](#type) for panel sizes). Links are `water` and underlined;
  inline code is `water` in the body font and size. Because Qt's Markdown
  renderer ignores `linkColor` and draws inline code in a larger fixed font,
  Markdown text passes through a helper that styles both spans beforehand.

## Panels

Panels follow four Japanese design principles, translated into concrete rules
below: *ma* (間), using negative space for structure; *kanso* (簡素), keeping
only what earns its place; *kata* (型), giving every panel the same layout; and
*shibui* (渋い), staying quiet until something needs attention. Any panel that
breaks a rule must explain why in a comment next to the code.

### Form

Every panel shares the same top-to-bottom structure:

- **Header:** The title sits on the left in 16 px `fg`. If the panel has no
  header slider or meter, it may display a single 16 px key value on the right
  in its status color. If the subsystem can be toggled off (such as Bluetooth),
  the on/off toggle button goes on the right instead and the subtitle reports
  the state.
- **Subtitle:** Optional 14 px `off` text describing what the key value belongs
  to, the current state ("Default route via Ethernet"), or why nothing is
  shown. Omit it when it would merely repeat content below.
- **Header slider or meter:** Optional control for the panel's primary value,
  placed 16 px below the header with no section label. Panels with one value
  per group (such as audio output and input volume) instead put each slider at
  the top of its group, 4 px above its rows.
- **Slider and meter values:** Placed to the right of the track at 14 px in a
  fixed column wide enough for `100%`, so stacked tracks end evenly. Values
  match the fill color (`off` while muted, or the meter's status color).
- **Groups:** Each group starts with a horizontal rule, with its section label
  on the left. If the group's content is self-describing (such as the battery
  details table or recording options), omit the label and use a bare rule. A
  group with a single display-only value (nightlight temperature, network
  interface) puts it on the right of the rule in `off`; a group-level control
  (such as Wi-Fi's power toggle) sits to the right of that. Place groups
  containing long lists last.
- **Multi-device panels:** Panels showing multiple devices with individual
  details (network, firmware) give each device its own group titled by device
  type ("Ethernet", "Wi-Fi"), with its interface name on the rule's right to
  distinguish duplicates. Devices without an interface (firmware) use their
  device name as the title.
- **Sub-groups:** When a group's items fall into a few categories (such as
  Wi-Fi networks: secured, open, out of range), split them into sub-groups and
  omit empty ones. Each sub-group heading is a focusable row containing a
  chevron (`󰅀` open, `󰅂` collapsed), a `fg` label, a rule, and an `off` item
  count. Sub-groups start collapsed so the panel reads at a glance; active
  state (such as the connected SSID and signal) lives in the group's details
  table.
- **Device pickers vs. action setup:** Panels for choosing a device (audio)
  list every device as a row, grouped by kind (Output, Input). Panels for
  configuring an action (recording) display one row per setting (label left,
  control right) so the entire configuration is visible at once: use
  `‹ value ›` (stepped with `h`/`l` or clicks) for many values, and a
  label-sized segmented control for a few options (On/Off, mirror target).
- **Details tables:** Multiple attributes of one item form a table with `off`
  labels and right-aligned `fg` values (or status-colored values such as `wood`
  for "Not synchronised"), all at 14 px. Use two key/value pairs per line in
  wide cards or when all values are short (weather). Share column widths across
  tables in the same panel so columns align. Truncate overly long values (such
  as SSIDs) with `…`; never truncate labels.
- **Held notifications:** Entries in the notification history keep their
  original toast card styling—tint, badge, and animation included—so they read
  just like the live notification.
- **Footer:** Lists only shortcuts unique to this panel (keycap + `off`
  description), omitting global panel keys (see
  [`interaction.md`](interaction.md) › Panels). Attribution or notes (such as
  weather's MET Norway and SMHI license) appear on their own line below.
  Panel-wide action buttons ("Bluetooth settings…", recording Pause/Stop) stay
  pinned on the footer's right so scrolling cannot hide them; group-specific
  buttons stay inside their group.

### Space

- **Spacing scale:** All gaps use 4, 8, 16, or 24 px:
  - `4 px`: subtitle below title; gap between list rows.
  - `8 px`: grid tiles (wallpapers); rule clearance from left label and right
    items; group content below a labeled rule; gap between sub-groups.
  - `16 px`: card padding; group content below a bare rule; sub-groups or a
    group's own button below preceding group content.
  - `24 px`: gap between groups.
- **Scrolling:** When groups exceed the screen height, they scroll between the
  fixed header and footer. While overflowing, a 4 px `dim` scrollbar (radius 2)
  appears inside the card's right padding, clear of row fills; it hides when
  everything fits. Scrolling lists end at their last row with no extra marker.
- **Alignment:** Group content aligns with the start of its rule. Sub-group
  headings and rows indent 16 px, lining the chevron up over the rows' icons.
  Row and slider `sel` fills extend 8 px into the card padding past the text.
- **Rules:** Space—not borders—separates groups. The only lines drawn in a
  panel are the 1 px `dim` rules heading groups and sub-groups, sitting inline
  with the label and extending to the right edge (or the right-side item). The
  header has no rule.

### Focus and state

- **Focus fill:** `sel` marks focus or hover and nothing else. Rows, sliders,
  and buttons indicate focus with `sel` alone: rows and sliders have no
  outline, and button outlines stay `dim`.
- **Selection marks:** The active choice in a list shows `●` at the start of
  its row; inactive choices show `○` in `dim`. Segmented controls (choices side
  by side in one outline) have no row prefix: the active label is `fg` and
  inactive labels are `off`. Unselectable options (such as a display mirror that
  would create a loop) and inactive buttons (such as Next with no next track)
  use `dim`—since `off` already means unselected—and are skipped by keyboard
  focus.
- **Device rows:** A device's leading icon shows `leaf` when connected and
  `off` otherwise. Secondary info (such as battery level) sits on the right in
  its status color; in-progress transitions ("Connecting…") appear there in
  `sky`. An audio device on an unplugged jack or empty HDMI port shows `󰚦` in
  `off` on the right and remains selectable.
- **Row actions:** A row whose only actions are buttons (such as Connect or
  Join) cannot itself be focused, highlighted with `sel`, or clicked; its
  right-aligned buttons (sized to the widest label) are the focus stops. A row
  that also has its own primary action (such as a calendar event that opens its
  app) keeps its own focus stop, followed by its buttons (such as Join).
- **Sliders and meters:** A slider is a 2 px `dim` track filled with `fg` up to
  its value, plus a 10 px knob; both fill and knob turn `off` when muted or
  disabled. A display-only meter uses the same track without a knob, coloring
  both its icon and fill with the value's status color.

### Type

- **Three sizes:** 16 px for panel titles and header key values; 14 px for
  subtitles, section labels, body text, and slider/meter values; 12 px for
  footers. All scale with the text scale.
- **Section labels:** Sentence case, 14 px, `fg`, placed at the left of their
  rule—the same size as body text, distinguished by the rule rather than color.
- **Timestamps:** Events from today format as `14:01`; earlier days format as
  `Wed 13:02`, without seconds
  ([`Ui/Time.js`](../stow/.config/quickshell/kaizen/Ui/Time.js)).
- **Meaningful color:** Color always conveys a role or status, never
  decoration.

## Status

- Status labels and icons take the color of their semantic role.
- A diagonal strikethrough on an icon marks an off state (disconnected,
  disabled, muted, or logged out). Temporarily disabled core features (Wi-Fi,
  Bluetooth, notifications) show this struck-through icon in `rose` as an
  alert. Plugins choose their own colors, follow the same strikethrough
  convention for off states, and may use `leaf` for connected, active, or
  logged-in states.
