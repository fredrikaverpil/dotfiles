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
| `blossom` | Headings |

## Shapes and text

- Buttons and inputs are outlined, 1 px at radius 4: `fg` focused and `dim`
  otherwise, filled with `sel` on focus or hover. List rows show focus with the
  `sel` fill alone. A field that failed (lock, polkit) turns its outline `rose`.
  The lock field and selections drawn over content take 2 px.
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

- A header: the title in `blossom` at 16 px on the left, and the panel's one
  key value (a volume, a charge, a network) at 16 px on the right, coloured by
  its status.
- A subtitle in `off` at 12 px: what the value belongs to, or why there is
  none.
- Groups, each a section label and its content.
- A footer with the panel's own keys: a keycap, then what it does in `off`. It
  lists only the keys the panel adds to those every panel shares
  ([`interaction.md`](interaction.md) › Panels).

### Space

- Spacing comes from one scale: 4, 8, 16 and 24 px. Rows in a list are 4
  apart, a label is 8 above its content, the card's padding is 16, and groups
  are 24 apart. The subtitle sits 4 under the title.
- Space separates groups. A panel draws no divider lines.

### Focus and state

- The `sel` fill marks focus or hover, and nothing else. Rows and sliders
  draw no outline; buttons keep theirs (Shapes and text).
- What is current or chosen shows as a mark at the start of its row: `●` for
  the chosen one of a set, `○` in `dim` for the others.
- A slider is a 2 px track in `dim`, filled `fg` up to its value, with a
  10 px knob; the fill and knob turn `off` while muted or off.

### Type

- Three sizes: 16 px for the title and the key value, 14 px for body text,
  12 px for secondary text and section labels. All scale with the text scale.
- A section label is in sentence case, 12 px, in `off`. Every group has one,
  even a panel's only group.
- Colour carries a role or a status, never decoration.

## Status

- A status colours its label or icon with its role.
- A diagonal strikethrough on an icon marks an off state such as disconnected,
  disabled, muted or logged out. A core feature that is temporarily off shows
  it in rose, as an alert (Wi-Fi, Bluetooth, notifications). A plugin picks its
  own colours but marks such states the same way, and may show the connected,
  active or logged-in state in green (`leaf`).
