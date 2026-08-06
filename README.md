# dotfiles 🍩

![screenshot](https://github.com/user-attachments/assets/51c05d03-d997-40dc-8757-4d13993fcafb)

Personal dotfiles, managed in three layers:

- **[Nix](https://nixos.org)** (`nix/`) — system configuration and packages,
  pinned by `flake.lock` and applied with a rebuild. Fully reproducible.
- **Stow** (`stow/`) — dotfiles symlinked into `$HOME` with
  [GNU Stow](https://www.gnu.org/software/stow/). Changes take effect
  immediately, no rebuild needed.
- **Package tools** — CLI tools installed by their own package managers
  (currently `uv` for Python, `deno` for npm). Nix declares _which_ tools and
  installs missing ones on rebuild, but versions are unpinned and upgraded
  manually.

## Quickstart

### Nix

> [!NOTE]
>
> - This requires having Nix installed. See
>   [the Nix README](extras/README_NIX.md).
> - The `flake.nix` is designed to set up the machine based on its hostname.

```sh
# Rebuild system + packages + dotfiles (reproducible, uses flake.lock)
sudo darwin-rebuild switch --flake ~/.dotfiles#"$(hostname -s)"  # macOS
sudo nixos-rebuild switch --flake ~/.dotfiles#"$(hostname -s)"   # NixOS

# Update ALL flake inputs, then rebuild
nix flake update

# Update only the unstable-pinned inputs, then rebuild
nix flake update nixpkgs-unstable nix-darwin home-manager-unstable llm-agents dotfiles

# Clean up old Nix generations, keeping the last 5 days for rollback safety
sudo nix-collect-garbage --delete-older-than 5d
```

> [!NOTE]
> On macOS, home-manager's per-user activation can silently fail to apply (a
> known upstream `launchctl asuser` flakiness). The rebuild self-heals this: a
> guard in `nix/shared/system/darwin.nix` verifies the activation landed and
> retries it, failing loudly otherwise. See `CLAUDE.md` for manual
> verification and recovery.

### Stow

Dotfiles are managed with GNU Stow, not Nix.

> [!NOTE]
>
> The `darwin-rebuild` and `nixos-rebuild` commands will run stow as well.

- Edit files in `stow/` directory and run stow
- Changes are immediately active (no rebuild needed)

```bash
# Apply dotfiles (no Nix rebuild needed)
cd ~/.dotfiles/stow
stow --target="$HOME" --restow --no-folding --adopt shared "$(uname -s)"
```

`--adopt` absorbs any real file that has replaced a managed symlink into the
repo instead of aborting; review the result with `git diff` before committing.

#### Shell

The shell entrypoint is `stow/shared/.zshrc`, which sources
`stow/shared/.zshrc_user`. The user file loads the shell configuration chain:

1. [`shell/exports.sh`](shell/exports.sh) — PATH (including
   [`shell/bin/`](shell/bin/) utils), globals, env vars
2. [`shell/aliases.sh`](shell/aliases.sh) — shell aliases
3. [`shell/sourcing.sh`](shell/sourcing.sh) — tool initialization, plugins,
   completions

See [Project config](extras/README_PROJECT.md) for details on shell
initialization, direnv, and per-project tooling.

### Package tools

> [!NOTE]
>
> I'm not happy with how this is designed, see
> [dotfiles#202](https://github.com/fredrikaverpil/dotfiles/issues/202).

CLI tools that come from language ecosystems rather than nixpkgs are declared
in Nix (see `nix/shared/home/package-tools.nix`) but installed by their native
package manager. A rebuild installs anything missing; upgrades are manual:

```sh
uv tool upgrade --all   # Python tools (uv)
npm-tools-upgrade       # npm tools (deno)
```

LLM agent CLIs (claude-code, opencode,...) are the exception: they are plain Nix
packages from the `llm-agents` flake input, upgraded via
`nix flake update llm-agents` + rebuild.

## Other READMEs and references

- Neovim ⌨️
  - [My Neovim config](nvim-fredrik/README.md) - uses `vim.pack`
  - [Minimalistic config](nvim-simple/README.md)
- Workflows 🌊
  - [Git config](extras/README_GIT.md)
  - [Project config](extras/README_PROJECT.md)
- Fonts
  - [Berkeley Mono](https://berkeleygraphics.com/typefaces/berkeley-mono) ❤️
  - [Maple Mono](https://github.com/subframe7536/maple-font)
  - [Noto Color Emoji](https://fonts.google.com/noto/specimen/Noto+Color+Emoji)
  - [Symbols Nerd Font Mono](https://github.com/ryanoasis/nerd-fonts)
- Host-specific documentation
  - [rpi5-homelab](nix/hosts/rpi5-homelab/README.md) - requires custom
    installation procedure
