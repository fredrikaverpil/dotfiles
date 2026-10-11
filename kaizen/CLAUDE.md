<!-- Loads when a file under kaizen/ is read; symlinked into kaizen directories elsewhere. -->

# kaizen

A Quickshell shell for niri, driven and verified by an agent from a terminal.
The docs are not loaded with this file: read the one the task needs, by its
path from the repository root.

## Read when

- `kaizen/README.md`: you change structure, add a module, host or surface, or
  need to know where something lives or which hosts it reaches.
- `kaizen/docs/development.md`: you edit anything under `kaizen/` or its Nix
  modules. Working model, gotchas, required checks, worktrees, building the
  `kaizen` command, deployment.
- `kaizen/docs/features.md`: you change or document a feature, or need an IPC
  target's calls.
- `kaizen/docs/plugins.md`: you write or change a plugin.
- `kaizen/docs/style.md`: you touch colours, shapes, text or status marks.
- `kaizen/docs/interaction.md`: you touch keys, menus, the bar, panels, the
  tray or an application's input.

## Hard rules

- Never restart Quickshell while the session is locked: the compositor keeps
  the lock after its client dies. `kaizen reload` and `kaizen dev` refuse
  while locked; do not go around them with `systemctl`.
- Ask the user to run Nix rebuilds; never run them.
- Use `kaizen ipc|reload|dev|shot|keys|doctor|status|focus`, not the raw
  tools they wrap (`qs ipc`, `systemctl --user restart`, `grim`, `wtype`).
  `kaizen --json` lists the commands. The table in `development.md`
  (Working model) says what each replaces.
- Run the checks for your change type before and after editing
  (`development.md`, Required local validation). Report coverage you could not
  run as pending.
- QML for a worktree is tried with `kaizen dev .`; run `kaizen dev off` before
  the task ends.
