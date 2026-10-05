# kaizen interaction

How the shell and its applications take input. How they look is in
[`style.md`](style.md); what each surface is and where it lives, in
[`README.md`](README.md).

These rules hold for every surface, core and plugin. A surface that breaks one
has a bug, as a pointer-only control does.

## Principles

- Keyboard first. Every action has a key path; the pointer only shortens it.
- Tab and Shift+Tab step through the controls. A list is one stop: Tab lands
  on its selected row, and arrows move inside it.
- Keys are shown. A row or control that has a key shows it as a keycap. A key
  is one that runs the same action: a niri bind for a shell row, the
  application's own key inside an application. A row without one shows none.
- One menu, many ways in. An action key, a right-click and a click on a chip
  open the same menu with the same rows. A right-click is never the only way
  to an action.
- Focus is the subject. An action applies to the focused object, or to the
  picked set when there is one. A right-click's subject is the clicked object,
  or the picked set when that object is picked.
- Esc closes the menu, panel or dialog that holds the keyboard, whole. Inside
  an application it clears one layer per press: the open menu, then the picked
  set, then the focused field.
- `?` lists the keys of the focused scope.

## Menus

One component draws every menu: the launcher, the bar's and tray's context
menus, and the menus inside applications. Its rows come from one tree: the
launcher's items for the shell, a tray item's own menu, or an application's
actions.

### Anatomy

- A search row comes first, always. Its placeholder names the level
  ("Filter clock…"); on its right is the key that opened the menu, when one
  did.
- A row shows an icon (the image when it has one, else the glyph), its label,
  a detail (a match's path, a value such as a zone's offset), its key and `›`
  when it has children. Check and radio rows show their state in the icon.
- Separators group rows; a query hides them. Disabled rows keep their place in
  `off`, and the cursor skips them.
- Rows are virtualized: a level can hold thousands (emoji).

### Search

- Typing always filters. A query matches the level's rows and every static
  row below it; deeper matches show their path as the detail. It reads no
  provider's rows but the level's own, so tray menus are reached by drilling
  into an item, and the root adds Apps.
- Hyphens are ignored ("wifi" finds "Wi-Fi"); rows with a key also match by
  it.
- Order is frecency (palette only), then the tree's order, with direct
  children before deeper matches. A context menu skips frecency so its rows
  stay where the hand expects them.

### Keys

| Key | Action |
| --- | --- |
| type | filter |
| `↑` `↓`, `Ctrl+N` `Ctrl+P` | move |
| `PageUp` `PageDown` | move ten rows |
| `→` | open the submenu |
| `←` | back one step while the search is empty, else move the text cursor |
| `Backspace` | delete a character, or back one step on an empty search |
| `Enter` | run the row, or open its submenu |
| `Esc` | close the menu |

- Letters are text, so `hjkl` and Space neither move nor run. `Ctrl+J` and
  `Ctrl+K` stay unbound: `Ctrl+K` opens an application's palette.
- Tab and Shift+Tab do nothing: the menu keeps the keyboard until it closes.
- Back is the same step in both placements: a cascade closes its last card, the
  palette returns to the parent level.
- Enter still repeating from the press that opened a submenu does not run the
  submenu's first row.
- The pointer: hover selects, and opens a submenu after a pause; a click runs.

### Placements

The same menu opens in one of two placements, decided by whether it has
something to hang from.

| | Context menu | Palette |
| --- | --- | --- |
| Opened by | right-click on a bar button, tray item, or an application's row or chip; an application key aimed at one control | `Mod+Space`; `Ctrl+K` in an application; `menu popup` and `menu level` over IPC |
| Position | hangs from its anchor, on the anchor's output; in an application, from the pointer or the chip | centred on the focused output, or over the application's window |
| Submenu | cascades beside its row | replaces the list; a breadcrumb above the search row names the path |
| Size | fits its rows | larger text; a level may ask for a wide card (Keybindings) |

- The launcher is the shell's tree in the palette, at the root.
- A shell menu is a layer surface with exclusive keyboard focus. An
  application's menu is drawn inside the application's window, over its
  content: it needs no second surface, the keyboard stays with the window, and
  it never leaves the window's bounds.

## Shell surfaces

### Bar

- The bar mirrors the launcher; nothing is reachable only from it. Every panel
  action is a launcher row under Settings, except sliders and per-item detail
  (forgetting a network, recording options).
- Bar buttons come in four kinds, told apart by what a click does:
  - ❄ and the workspaces: left-click opens the launcher, right-click its top
    level as a context menu; a workspace takes focus.
  - Panel buttons: left-click opens the panel, right-click the button's
    Settings node as a context menu. The date is one only when a plugin takes
    it over, and opens the plugin's node; otherwise it is a plain label.
  - Indicators, shown only off the default state: left-click acts on it
    (stops the recording or every mirror, re-enables idle locking, resets the
    layout). The system alert is a plain label.
  - Tray items: the app's own activation and menu.

### Panels

- A panel shows and adjusts a subsystem; its actions are also Settings rows,
  so a panel is never the only way to one.
- It opens centred with exclusive keyboard focus. Arrows and `hjkl` step
  focus as Tab does, since a panel has no search to type into; Enter and Space
  activate; Esc closes.
- A control with its own key shows it.

### Tray

- A tray item's left-click is the app's activation; its right-click opens the
  app's menu as a context menu. The launcher's Tray level lists the items.
- A tray menu's rows come from the app, so they carry no keys, and root search
  does not read them.

## Applications

An application is a complex UI in a normal window, such as the incident
investigator: it stays up while others have focus, and niri's window binds
(`Mod+Q`) treat it as any other window.

- The launcher only opens an application (its plugin node) and shows its tray
  menu. The application's own actions stay in its palette; the shell's tree
  never holds them.
- `Ctrl+K` opens the application's palette on what has focus: the focused
  object's actions, then those of each scope around it (its list or pane,
  then the window), each with its key where that key runs it. The breadcrumb
  names the scopes.
- Single-letter keys are optional. An application may give frequent actions
  one; it acts on the focused object while no text field has focus. In a text
  field only Esc, Enter and Ctrl chords act: Esc leaves the field, and
  `Ctrl+Enter` submits. An application's keys never become niri binds.
- A property (tag, project, model) is a chip showing its value. A click, or
  its key when it has one, opens a context menu on the chip; picking a row
  sets it.
- A right-click on an object opens its context menu: the palette's rows for
  that object.
- Lists: `↑` `↓` (and `j` `k`) move, and with Shift pick a range; Enter opens
  and takes focus into what it opened; Space picks, Esc unpicks, Backspace or
  Delete deletes.
- A destructive action asks inline: `y` or Enter confirms, `n` or Esc cancels.

### Incident investigator

The investigator has no single-letter action keys: `Ctrl+K` (or `?` outside a
text field) opens the palette, and the list takes the keys above. Enter on a
row moves focus to its draft's notes or its follow-up field; Esc goes back to
the row.

- Active filters show as chips above the list; each clears with a click or
  from the filter menu.
- A draft's composer carries the chips Tag, Projects, Model and Effort beside
  its notes, and runs on `Ctrl+Enter`. Model and Effort pick what the next run
  starts with (`settings`).
- A row's context menu holds Open, Run or Re-run, Tag ›, Combine (with a picked
  set) and Delete. A message's holds Copy, Copy selection, Edit (your own) and
  Branch.
