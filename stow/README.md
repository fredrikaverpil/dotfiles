# Stow

```sh
# edit files in stow/ and then run:
dotfiles-stow
```

Stow forbids slashes in package names, so each level is its own invocation:

| Package | Applies to |
| --- | --- |
| `stow/shared/` | every machine |
| `stow/platform/{Darwin,Linux}/` | matching `uname -s` |
| `stow/kaizen/` | kaizen hosts, where `/etc/kaizen` exists (`renoir`, `wily`) |
| `stow/host/<hostname>/` | that machine only; optional |

`--adopt` absorbs any real file that has replaced a managed symlink into the
repo instead of aborting; review the result with `git diff` before committing.

## Shell

The shell entrypoint is `stow/shared/.zshrc`, which sources
`stow/shared/.zshrc_user`. The user file loads the shell configuration chain:

1. [`stow/shared/.shell/exports.sh`](stow/shared/.shell/exports.sh) — PATH
   (including [`bin/`](stow/shared/.shell/bin/) utils), globals, env vars
2. [`stow/shared/.shell/aliases.sh`](stow/shared/.shell/aliases.sh) — shell
   aliases
3. [`stow/shared/.shell/sourcing.sh`](stow/shared/.shell/sourcing.sh) — tool
   initialization, plugins, completions
