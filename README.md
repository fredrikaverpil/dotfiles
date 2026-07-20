# dotfiles 🍩

![screenshot](https://github.com/user-attachments/assets/51c05d03-d997-40dc-8757-4d13993fcafb)

Personal dotfiles using [Nix](https://nixos.org) for reproducible system/package
management and [GNU Stow](https://www.gnu.org/software/stow/) for dotfile
symlinking.

## Quickstart

### Nix

> [!NOTE]
>
> - This requires having Nix installed. See
>   [the Nix README](extras/README_NIX.md).
> - The `flake.nix` is designed to set up the machine based on its hostname.

```sh
# Rebuild system + packages + dotfiles (reproducible, uses flake.lock)
sudo darwin-rebuild switch --flake ~/.dotfiles#<host>   # macOS (zap, plumbus)
sudo nixos-rebuild switch --flake ~/.dotfiles#rpi5-homelab  # NixOS

# Update ALL flake inputs, then rebuild
nix flake update

# Update only the unstable-pinned inputs, then rebuild
nix flake update nixpkgs-unstable nix-darwin home-manager-unstable llm-agents dotfiles

# After updating, refresh package-managed CLI tools
uv tool upgrade --all
npm-tools-upgrade

# Dotfiles only (no Nix rebuild)
cd ~/.dotfiles/stow && ./install.sh

# Clean up old Nix generations, keeping the last 5 days for rollback safety
sudo nix-collect-garbage --delete-older-than 5d
```

> [!NOTE]
> On macOS, home-manager's per-user activation can silently fail to apply
> (a known upstream `launchctl asuser` flakiness — no config-level fix
> exists). After rebuilding, verify with `readlink /run/current-system` and
> `nix profile list | grep -A1 home-manager-path`; see `CLAUDE.md` for the
> fallback command if it's stale.

### Dotfiles

Dotfiles are managed with GNU Stow, not Nix:

- Edit files in `stow/` directory and run stow
- Changes are immediately active (no rebuild needed)
- Nix runs stow commands during home-manager activation

```bash
# Manual stow (if needed)
cd ~/.dotfiles/stow
stow --target="$HOME" --restow shared "$(uname -s)"

# If some tool replaced a symlinked config with a real file (breaking the
# stow), re-run with --adopt to absorb it into the repo instead of aborting.
# Review with `git diff` before committing -- nothing is staged automatically.
./install.sh --adopt
```

### Shell

The shell entrypoint is `stow/shared/.zshrc`, which sources
`stow/shared/.zshrc_user`. The user file loads the shell configuration chain:

1. [`shell/exports.sh`](shell/exports.sh) — PATH (including
   [`shell/bin/`](shell/bin/) utils), globals, env vars
2. [`shell/aliases.sh`](shell/aliases.sh) — shell aliases
3. [`shell/sourcing.sh`](shell/sourcing.sh) — tool initialization, plugins,
   completions

See [Project config](extras/README_PROJECT.md) for details on shell
initialization, direnv, and per-project tooling.

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
