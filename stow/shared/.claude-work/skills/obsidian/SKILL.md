---
name: obsidian
description:
  Find, navigate, read, and edit notes in the user's personal Obsidian vault (an
  iCloud-synced markdown collection on macOS). Use whenever the user mentions
  "the vault", "my notes", "Obsidian", a daily note, a meeting note, scratchpad,
  or asks to look up/jot down something that sounds personal-knowledge-base-like
  (e.g. "what did I write about X", "add a note about Y", "today's daily note")
  — even if they don't say the word "Obsidian".
---

# Obsidian vault

The user keeps a personal Obsidian vault as plain markdown files synced via
iCloud. The vault is just a directory tree, so all standard Unix tools work — no
Obsidian app required to read or write notes.

## Where it lives

```
/Users/fredrik/Library/Mobile Documents/iCloud~md~obsidian/Documents/work
```

Because the path contains spaces and tildes, **always quote it** in shell
commands. A useful shorthand is to assign it once per session:

```bash
VAULT="/Users/fredrik/Library/Mobile Documents/iCloud~md~obsidian/Documents/work"
```

If `$VAULT` doesn't exist (e.g. on a non-mac host or before iCloud has synced),
stop and tell the user — don't fabricate notes.

## How the user normally interacts with it

The user edits the vault from Neovim via the
[`obsidian.nvim`](https://github.com/obsidian-nvim/obsidian.nvim) plugin.
Configuration (workspace path, daily-notes folder, template settings, keymaps)
lives in `nvim-fredrik/plugin/obsidian.lua` in this dotfiles repo — read it when
you need the current setup, since it changes occasionally and this skill should
not duplicate it.

When suggesting a workflow, prefer pointing the user at the relevant keymap or
`:Obsidian` command (look them up in that file) over spawning a shell command,
unless they're clearly outside Neovim.

## Folder layout

```
$VAULT/
├── Daily/                  # Daily notes, one file per day: YYYY-MM-DD.md
├── Meeting notes/          # Meeting notes (template: meeting_notes.md)
├── Resources/              # PARA-style references (Go/, Postgres/, Neovim/, ...)
├── Ideas/                  # Half-baked ideas
├── Archive/                # Things no longer active
├── Clippings/              # Web clippings
├── _templates/             # Frontmatter templates (daily.md, meeting_notes.md)
├── _excalidraw/            # Excalidraw drawings
├── .trash/                 # Obsidian's soft-delete bin (treat as deleted)
└── *.md                    # A handful of loose top-level notes
                            # (scratchpad.md, Running.md, LEARNING.md, blog drafts)
```

Underscored folders (`_templates`, `_excalidraw`) sort to the top in the
Obsidian UI — they're conventions, not hidden files. Skip `.trash/` when
searching unless the user explicitly asks about deleted notes.

## Note conventions

### Filenames

- Daily notes: `Daily/YYYY-MM-DD.md` (e.g. `Daily/2026-05-08.md`).
- Other new notes created via the Neovim plugin are prefixed with today's date:
  `YYYY-MM-DD-<title>.md`. Match this pattern when creating notes
  programmatically.
- Filenames may contain spaces (`API design.md`) and emoji (`🧚‍♀️ LEARNING.md`).

### Frontmatter

Every note has YAML frontmatter. Minimum shape:

```yaml
---
id: <usually filename without .md>
aliases: []
tags: []
categories: []
---
```

Daily notes also include `date: YYYY-MM-DD` and `tags: [daily-notes]`. Meeting
notes include `company: "[[Einride]]"` and `date`. When creating a new note,
copy the relevant template from `_templates/` rather than hand-rolling
frontmatter.

### Links

Notes use **Obsidian wikilinks** in _shortest_ form:

- `[[API design]]` — link by note title (no path, no `.md`)
- `[[API design|how we design APIs]]` — with display text
- `[[API design#Choose level of abstraction]]` — link to a heading

Standard markdown links (`[text](path.md)`) are not used — preserve wikilink
style when editing.

## Finding things (portable, no Obsidian needed)

Prefer `rg` and `fd`; fall back to `grep`/`find` if those aren't installed.
Always exclude `.obsidian/` and `.trash/` to keep results signal-rich.

```bash
# Find notes by filename (case-insensitive, fuzzy on basename)
fd -tf 'pattern' "$VAULT" -E .obsidian -E .trash

# Full-text search across notes, with filename + line context
rg --type md -n 'search term' "$VAULT" -g '!.obsidian' -g '!.trash'

# Find all notes tagged X (frontmatter or inline #tag)
rg --type md -n '(^|\s)#X\b|tags:.*\bX\b' "$VAULT" -g '!.obsidian' -g '!.trash'

# Find backlinks to a note titled "API design"
rg --type md -n '\[\[API design(\||#|\]\])' "$VAULT" -g '!.obsidian' -g '!.trash'

# Today's daily note (create-if-missing pattern)
TODAY="$VAULT/Daily/$(date +%Y-%m-%d).md"
```

For broader exploration (e.g. "what notes do I have about Postgres?"), look at
both filenames and full-text — the user organizes by both folder and tag.

## Creating notes

When the user asks you to add a note, follow these rules:

1. **Pick the right folder** based on intent: daily entry → `Daily/`, meeting →
   `Meeting notes/`, work topic → `Einride/<area>/`, durable reference →
   `Resources/<topic>/`, half-formed thought → `Ideas/` or append to
   `scratchpad.md`.
2. **Use the matching template** from `_templates/` as the starting point.
   Replace `{{date}}` with `YYYY-MM-DD` and `{{title}}` with the note's title.
3. **Set `id`** to the filename without `.md` (the Neovim plugin uses
   `YYYY-MM-DD-<title>` for non-daily notes — match that for consistency).
4. **Use wikilinks** for any cross-references, not markdown links.

If unsure which folder fits, ask — folder choice is how the user finds things
later.

## Editing notes

- Preserve existing frontmatter exactly; only add fields that are missing.
- Don't rewrite `id` even if the filename suggests a different one (it may be a
  deliberate alias).
- Keep the wikilink style — if the user wrote `[[Foo]]`, don't "improve" it to
  `[Foo](Foo.md)`.

## Plugins worth knowing about

The vault has two community plugins enabled (see
`.obsidian/community-plugins.json`):

- **frontmatter-generator** — auto-fills frontmatter on note creation in the
  Obsidian app. Notes created from the shell won't go through it, so copy from
  `_templates/` to get equivalent output.
- **obsidian-excalidraw-plugin** — drawings live in `_excalidraw/` as
  `.excalidraw.md` files. Treat them as opaque unless the user asks
  specifically.
