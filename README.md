# dotfiles 🍩

![screenshot](https://github.com/user-attachments/assets/ef833ca0-3d39-4a7c-94af-0f76afb96e6b)

Personal dotfiles using [Nix](https://nixos.org) for reproducible system/package
management and [GNU Stow](https://www.gnu.org/software/stow/) for dotfile
symlinking.

## Quickstart

### Nix

> [!NOTE]
>
> - This requires having installed Nix. See
>   [the Nix README](extras/README_NIX.md).
> - The `flake.nix` is designed to set up the machine based on its hostname.

```sh
# Rebuild system + packages + dotfiles (reproducible, uses flake.lock)
./rebuild.sh

# Update ALL flake inputs + upgrade uv tools + upgrade bun packages
./rebuild.sh --update

# Update unstable inputs + upgrade uv tools + upgrade bun packages
./rebuild.sh --update-unstable

# Dotfiles only (no Nix rebuild)
./rebuild.sh --stow
```

### Dotfiles

Dotfiles are managed with GNU Stow, not Nix:

- Edit files in `stow/` directory and run stow
- Changes are immediately active (no rebuild needed)
- Nix runs stow commands during home-manager activation

```bash
# Manual stow (if needed)
cd ~/.dotfiles/stow
stow --target="$HOME" --restow shared "$(uname -s)"
```

## Other READMEs and references

### Neovim ⌨️

- [nvim-fredrik](nvim-fredrik/README.md)

### Git 🐙

- [Configure git](extras/README_GIT.md)

### Project config/tooling 🧢

- [Configure projects](extras/README_PROJECT.md)

### Fonts 💯

- [Berkeley Mono](https://berkeleygraphics.com/typefaces/berkeley-mono)
- [Maple Mono](https://github.com/subframe7536/maple-font)
- [Noto Color Emoji](https://fonts.google.com/noto/specimen/Noto+Color+Emoji)
- [Symbols Nerd Font Mono](https://github.com/ryanoasis/nerd-fonts)

### Host-specific documentation

- [rpi5-homelab](nix/hosts/rpi5-homelab/README.md) - requires custom
  installation procedure
