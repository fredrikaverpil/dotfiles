# kaizen style

How the shell looks. What kaizen is and where each part lives is in
[`README.md`](README.md).

## Palette

The palette is [zenbones](https://github.com/zenbones-theme/zenbones.nvim)' dark
and light variants, defined once in
[`shell.qml`](../../stow/kaizen/.config/quickshell/shell.qml) and followed by
the theme toggle. QML reads colours from `shell.palette`, never as hex literals.
The roles below are the default: core follows them, a plugin starts from them
and may deviate.

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
- Text is `Ui.Fonts.mono`. Links are `water` and underlined; inline code is
  `water` in the body's font and size. Qt's Markdown rendering ignores
  `linkColor` and draws code in its own larger fixed font, so markdown text goes
  through a helper that colours both spans first.

## Status

- A status colours its label or icon with its role.
- A diagonal strikethrough on an icon marks an off state such as disconnected,
  disabled, muted or logged out. A core feature that is temporarily off shows
  it in rose, as an alert (Wi-Fi, Bluetooth, notifications). A plugin picks its
  own colours but marks such states the same way, and may show the connected,
  active or logged-in state in green (`leaf`).
