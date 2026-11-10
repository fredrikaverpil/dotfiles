# kaizen style

How the shell looks. What kaizen is and where each part lives is in
[`README.md`](../README.md).

## Palette

The palette is [zenbones](https://github.com/zenbones-theme/zenbones.nvim)' dark
and light variants, defined once in
[`Ui/Palette.js`](../stow/.config/quickshell/kaizen/Ui/Palette.js) and
followed by the theme toggle in
[`shell.qml`](../stow/.config/quickshell/kaizen/shell.qml). QML reads colours from `shell.palette`, never as
hex literals. The roles below are the default: core follows them, a plugin
starts from them and may deviate.

| Role | Meaning |
| --- | --- |
| `bg`, `fg` | Surface, text, focused outline |
| `dim` | Unfocused outline, card border |
| `sel` | Hover, focus and selection fill |
| `off` | Secondary text, hints, unavailable, cancelled, logged out |
| `rose` | Needs attention: error, failure, a core feature off, something live (recording, idle inhibited), production |
| `wood` | Warning, draft |
| `leaf` | Success, done, connected, logged in |
| `sky` | Running, in progress |
| `water` | Accent and information: links, inline code, the active window border, a neutral tag |
| `blossom` | Headings in rendered Markdown |

## Shapes and text

- Buttons and inputs are outlined, 1 px at radius 4: `fg` focused and `dim`
  otherwise, filled with `sel` on focus or hover; in a panel the outline stays
  `dim` (Panels). List rows show focus with the `sel` fill alone. A field that
  failed (lock, polkit) turns its outline `rose`. The lock field and selections
  drawn over content take 2 px.
- Surfaces (panel, context menu, notification, OSD) have radius 8.
- A key is a keycap per key (`Super` `Space`), set apart from the label it
  belongs to: `off` text a size smaller, outlined `dim` at radius 3 with a 2 px
  bottom edge. A menu row puts it in a column on the right.
- Text is `Ui.Fonts.mono` at 14 px, times the text scale; secondary text is
  12 px. Links are `water` and underlined; inline code is
  `water` in the body's font and size. Qt's Markdown rendering ignores
  `linkColor` and draws code in its own larger fixed font, so markdown text goes
  through a helper that colours both spans first.

## Panels

Panels borrow four ideas from Japanese design, each turned into rules below:
ma (間), the space between things, as structure; kanso (簡素), keeping only
what earns its place; kata (型), one form that every panel follows; and shibui
(渋い), quiet until something matters. A panel that breaks a rule needs a
reason, written next to the code.

### Form

Every panel has the same shape, top to bottom:

- A header: the title in `fg` at 16 px on the left. A panel without a
  slider or meter may put its one key value at 16 px on the right, coloured
  by its status. A panel whose subsystem turns off (bluetooth) puts
  the button that turns it on or off there instead, and its subtitle says the
  state.
- A subtitle in `off` at 14 px: what the value belongs to, the panel's
  state ("Default route via Ethernet"), or why there is none. Left out when
  it would repeat what the panel shows below.
- Optionally, a slider or meter for the key value, 16 under the header. It is
  part of the header: no section label.
- A slider's or meter's value sits right of its track at 14 px, in a column
  as wide as `100%`, so stacked tracks end together. It takes the fill's
  colour: `off` while muted, the status colour on a meter.
- Groups, each a section label, ruled underneath, and its content. A group
  with one value of its own that no control shows (nightlight's temperature)
  puts it at the label's right in `off`; a group with a control of its own
  (Wi-Fi's power button) puts that there instead.
- A panel over several devices, each with details of its own (network), gives
  each device a group titled by its type ("Ethernet", "Wi-Fi"). A group
  holding a long list goes last.
- Many values about one thing form a details table: labels in `off`, values
  in `fg` right-aligned, both 14 px, two pairs to a line in a wide card. A
  panel's tables share their column widths, so they line up.
- A footer with the panel's own keys: a keycap, then what it does in `off`. It
  lists only the keys the panel adds to those every panel shares
  ([`interaction.md`](interaction.md) › Panels). A button acting on the
  whole panel ("Pair new device…") sits at its right, where no scrolling
  hides it; a group's own button stays in its group.

### Space

- Spacing comes from one scale: 4, 8, 16 and 24 px. Rows in a list are 4
  apart, a section label's rule is 4 under it and 8 above its content, the
  card's padding is 16, and groups are 24 apart. The subtitle sits 4 under the title.
- Groups too tall for the screen scroll between a fixed header and footer.
  While they overflow, a 4 px `dim` bar at radius 2 sits in the card's
  right padding, clear of the rows' fill; it shows nothing when all fits.
- A group's content aligns with its section label. A row's or slider's `sel`
  fill reaches 8 into the card's padding, past the text it holds.
- Space separates groups. The only lines a panel draws are the rules under
  its section labels: 1 px `dim`, as wide as the group. The header has none.

### Focus and state

- The `sel` fill marks focus or hover, and nothing else. Rows, sliders and
  buttons show focus with it alone: rows and sliders draw no outline, and a
  button's stays `dim`.
- What is current or chosen shows as a mark at the start of its row: `●` for
  the chosen one of a set, `○` in `dim` for the others. A segmented control,
  a few choices side by side in one outline, has no row start: its chosen
  label is `fg`, the others `off`. An option that cannot be picked (a mirror
  that would loop) is `dim`, since `off` already means unchosen there, and
  focus skips it.
- A device's state shows in its icon at the start of its row: `leaf` while
  connected, `off` otherwise. What it reports, such as its battery, sits at
  the row's right in its status colour; a change under way ("Connecting…")
  sits there in `sky`.
- A row whose actions are buttons (a device's Connect, a network's Join) takes
  no focus, `sel` fill or click: its buttons, at its right and as wide as
  their longest label, are the stops.
- A slider is a 2 px track in `dim`, filled `fg` up to its value, with a
  10 px knob; the fill and knob turn `off` while muted or off. A meter, which
  only shows a value, is the same track without the knob, its icon and fill
  in the value's status colour.

### Type

- Three sizes: 16 px for the title and the key value; 14 px for the subtitle,
  section labels and body text; 12 px for the footer. All scale with the text
  scale.
- A section label is in sentence case, 14 px, in `fg`, over its rule: no
  smaller than the body it heads, and set apart from it by the rule, not by
  colour. Every group has one, even a panel's only group.
- Colour carries a role or a status, never decoration.

## Status

- A status colours its label or icon with its role.
- A diagonal strikethrough on an icon marks an off state such as disconnected,
  disabled, muted or logged out. A core feature that is temporarily off shows
  it in rose, as an alert (Wi-Fi, Bluetooth, notifications). A plugin picks its
  own colours but marks such states the same way, and may show the connected,
  active or logged-in state in green (`leaf`).
