# kaizen interaction

Input and navigation rules for the shell and its applications. For visual
design, see [`style.md`](style.md); for surface architecture and file paths,
see [`README.md`](../README.md).

These rules apply to every surface, both core and plugin. Breaking one is a
bug, just like a pointer-only control.

## Principles

- **Keyboard first:** Every action has a keyboard path; the pointer is only a
  shortcut.
- **Tab navigation:** `Tab` and `Shift+Tab` step between controls. A list is a
  single Tab stop: `Tab` lands on the selected row, and arrow keys move within
  the list.
- **Visible shortcuts:** Any row or control with a shortcut displays it as a
  keycap—a compositor bind for shell rows, or an app shortcut inside an
  application. Rows without shortcuts show none.
- **One menu, many entry points:** An action shortcut, a right-click, and a
  chip click all open the same menu with the same rows. Right-click is never
  the only way to reach an action.
- **Focus defines the target:** Actions apply to the focused item, or to the
  selected set if items are selected. Right-clicking targets the clicked item—or
  the selected set if the clicked item belongs to it.
- **Predictable `Esc`:** In shell surfaces, `Esc` immediately closes the active
  menu, panel, or dialog. Inside applications, `Esc` unwinds one layer per
  press: open menu → selected set → focused input field.
- **Shortcut help:** `?` lists available shortcuts for the focused scope.

## Menus

One component renders every menu: the launcher, bar and tray context menus, and
in-app menus. Each menu reads from a single item tree—the shell launcher tree,
a tray item's D-Bus menu, or an application's actions.

### Anatomy

- **Search bar:** Always appears first. Its placeholder names the current level
  ("Filter time…"), and the right side displays the shortcut that opened the
  menu (when applicable).
- **Rows:** Each row shows an icon (image if available, otherwise a glyph),
  label, optional detail (such as a deeper match's path or a timezone offset),
  shortcut keycap, and `›` if it opens a submenu. Check and radio rows show
  their state in the icon.
- **Separators and visibility:** Separators group rows and disappear while
  filtering. Disabled rows remain visible in `off` and are skipped by keyboard
  navigation. Rows for features unsupported by the active compositor are
  hidden.
- **Virtualization:** Lists are virtualized so a single level can hold
  thousands of rows (such as emoji).

### Search

- Typing always filters. A query searches the current level and all static
  descendants below it, showing each deeper match's path in its detail column.
  Search does not query dynamic providers inside child levels (so tray menus
  are searched only after opening a tray item), except at the root level, which
  also includes Apps.
- Hyphens are ignored ("wifi" matches "Wi-Fi"), and rows with shortcuts also
  match on their shortcut text.
- Results are ordered by frecency (in palettes only), then tree order, with
  direct children ranked ahead of deeper matches. Context menus disable
  frecency so row positions stay predictable for muscle memory.
- Application menu levels can allow creating new entries from the search box:
  the final row displays an `off` hint when empty and switches to
  `Add "<query>"` while typing, unless an existing row already has that name.

### Keys

| Key | Action |
| --- | --- |
| type | filter |
| `↑` `↓`, `Ctrl+N` `Ctrl+P` | move selection |
| `PageUp` `PageDown` | move ten rows |
| `→` | open submenu |
| `←` | go back one level (when search is empty), or move text cursor |
| `Backspace` | delete character, or go back one level when search is empty |
| `Enter` | activate row or open submenu |
| `Esc` | close menu |

- Letters always type into the filter, so `hjkl` and `Space` do not navigate or
  activate rows. `Ctrl+J` and `Ctrl+K` stay unbound (`Ctrl+K` opens an
  application's command palette).
- `Tab` and `Shift+Tab` do nothing; the menu holds keyboard focus until closed.
- Going back works identically in both placements: it closes the rightmost card
  in a cascading context menu, or returns to the parent level in a palette.
- Key repeat on `Enter` after opening a submenu will not activate the submenu's
  first row.
- With the pointer, hovering selects a row and opens submenus after a brief
  delay; clicking activates.

### Placements

The same menu opens in one of two placements depending on whether it has an
anchor:

| | Context menu | Palette |
| --- | --- | --- |
| Opened by | right-click on a bar button, tray item, or app row/chip; an app shortcut targeting one control | `Mod+Space`; `Ctrl+K` in an app; `menu popup` and `menu level` over IPC |
| Position | anchored to its trigger on that output (or to the pointer/chip inside an app) | centered on the focused output, or over the app window |
| Submenu | cascades beside its parent row | replaces the list, with a breadcrumb above the search bar |
| Size | fits its rows | standard width, unless a level requests a wide card (Keybindings) |

- The launcher is the shell's menu tree opened as a palette at its root.
- Shell menus are layer surfaces with exclusive keyboard focus. Application
  menus render inside the application window over its content—requiring no
  extra surface, keeping keyboard focus in the window, and staying within
  window bounds.

## Shell surfaces

### Bar

- The bar mirrors the launcher; nothing is accessible only from the bar. Every
  panel action also lives under **Settings** in the launcher, except sliders
  and item-specific details (such as forgetting a network or tweaking recording
  options).
- Bar items fall into four kinds based on click behavior:
  - **Menu (`❄`) and workspaces:** Left-clicking `❄` opens the launcher;
    right-clicking opens the top level as a context menu. Clicking a workspace
    focuses it.
  - **Panel buttons:** Left-click toggles the panel open or closed; right-click
    opens its **Settings** subtree as a context menu. The date behaves as a
    panel button only when claimed by a plugin (opening the plugin's node);
    otherwise it is a plain label.
  - **Indicators:** Shown only when off the default state. Left-click either
    acts directly (stopping recording or mirrors, re-enabling idle lock,
    resetting keyboard layout) or toggles its panel (doctor, firmware). The
    system alert indicator is a plain label.
  - **Tray items:** Forward left-click activation and right-click menus to the
    app.

### Panels

- Panels view and adjust a subsystem. Their actions also exist as **Settings**
  rows in the launcher, so a panel is never the only path to an action.
- Panels open centered with exclusive keyboard focus and nothing focused
  initially, so the first navigation step lands on the first control. Because
  panels have no search input, both arrow keys and `hjkl` step focus just like
  `Tab`. `Enter` and `Space` activate; `Esc` closes. Value controls (sliders
  and `‹ value ›` steppers) consume `←`/`→` and `h`/`l` to adjust their value.
- Hovering a row or slider moves focus to it so only one item shows the `sel`
  fill at a time. A row that appears or scrolls beneath a stationary pointer
  does not steal focus.
- Activating a sub-group heading (`Enter`, `Space`, or click) toggles it open
  or closed; that state persists until the shell restarts.
- Controls with dedicated shortcuts display them as keycaps, and the panel
  footer lists every panel-specific key beyond the defaults above (see
  [`style.md`](style.md) › Panels).

### Tray

- Left-clicking a tray item triggers the app's activation; right-clicking opens
  the app's menu as a context menu. The launcher's **Tray** level lists all
  tray items.
- If tray items overflow the space beside the clock, they collapse into a
  single tray button. Either click opens the launcher's **Tray** level as a
  context menu from that button, with each item's menu cascading out.
- Tray menu rows come from the app itself, so they carry no shortcuts and are
  excluded from root search.

## Applications

An application is a complex UI in a regular window (such as the incident
investigator). It stays open while other windows are focused, and compositor
window binds (like `Mod+Q`) treat it like any other window.

- The launcher only launches the application (via its plugin node) and exposes
  its tray menu. All internal actions live in the application's own palette,
  never in the shell tree.
- `Ctrl+K` opens the application palette scoped to the current focus: actions
  for the focused item first, followed by each enclosing scope (its list or
  pane, then the window), with shortcuts shown where active. The breadcrumb
  reflects the scope chain.
- Single-letter shortcuts are optional. When defined, they act on the focused
  item whenever no text field is focused. Inside a text field, only `Esc`,
  `Enter`, and `Ctrl` chords act (`Esc` leaves the field; `Ctrl+Enter`
  submits). Application shortcuts never become compositor binds.
- Multiline text fields grow with their text, then scroll to keep the cursor
  in view. Drag the grip in the lower-right corner to resize; double-click it
  to grow with the text again. Where plain `Enter` submits (a chat input),
  `Shift+Enter` inserts a newline.
- Properties (tag, project, model) appear as chips showing their value, or
  their name in `off` when unset. Clicking a chip, pressing `Enter`/`Space` on
  it, or hitting its shortcut opens an anchored context menu to set the value.
- Right-clicking an item opens its context menu with the same rows shown in the
  palette for that item.
- **Lists:** `↑`/`↓` (and `j`/`k`) move focus; adding `Shift` selects a range.
  `Enter` opens the item and moves focus into it; `Space` toggles selection;
  `Esc` clears selection; `Backspace` or `Delete` deletes.
- Destructive actions confirm inline: `y` or `Enter` confirms; `n` or `Esc`
  cancels.

### Incident investigator

The incident investigator defines no single-letter action keys: `Ctrl+K` (or
`?` outside a text field) opens the palette, and the investigation list uses
the standard list keys above. Pressing `Enter` on a row moves focus to its
draft notes or follow-up input; `Esc` returns focus to the row.

- Active filters appear as chips above the list; clear them by clicking a chip
  or via the filter menu.
- A draft's composer shows **Tag**, **Projects**, **Model**, and **Effort**
  chips below the notes field and submits on `Ctrl+Enter`; typing in
  **Projects ›** lets you add a new project. The follow-up bar shows **Model**
  and **Effort** (selecting the defaults for the next run via `settings`), and
  the conversation header shows **Tag**.
- Combined investigations list their source investigations as buttons under
  **Combined from** (and under **Combined from ›** in the palette), each
  jumping to its source row. Selecting a combined investigation highlights its
  sources in the list.
- A row's context menu contains **Open**, **Run** / **Re-run**, **Tag ›**,
  **Combine** (when multiple rows are selected), and **Delete**. A message's
  context menu contains **Copy** (or **Copy selection** when text is selected),
  **Edit** (on your own messages), and **Branch**.
