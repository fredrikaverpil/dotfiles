# dotfiles 🍩

![screenshot](https://github.com/user-attachments/assets/ef833ca0-3d39-4a7c-94af-0f76afb96e6b)

These are my personal dotfiles. The setup is based on [nix](https://nixos.org)
(for reproducibility), [GNU Stow](https://www.gnu.org/software/stow/) (for
symlinking of dotfiles) and aims to be as idempotent as possible.

## Quick Start 🚀

### Prerequisites

- **macOS/Linux**: Xcode Command Line Tools (macOS) or build essentials (Linux)
- **Administrator privileges** for initial setup

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/fredrikaverpil/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# 2. Install Nix (recommended)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# 3. Initial setup
# - macOS - requires sudo for first-time system activation
sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake ~/.dotfiles#$(hostname)
# - Linux/NixOS
sudo nixos-rebuild switch --flake ~/.dotfiles#$(hostname)
```

### Daily Usage

```bash
# Rebuild configuration after changes (macOS requires sudo)
sudo ./rebuild.sh

# Update packages and rebuild (macOS requires sudo)
sudo ./rebuild.sh --update

# Use Stow fallback (no sudo required)
./rebuild.sh --stow
```

> [!NOTE] **macOS**: `sudo` is required for all nix-darwin rebuilds due to
> system activation requirements. **Linux**: `sudo` is only required for initial
> setup, then `./rebuild.sh` works without `sudo`.

## Systems 🚀

### Managed with Nix + Stow

- See the [nix/README.md](nix/README.md) docs.

### Managed with Stow only

- [macOS](README_MACOS.md)
- [Windows 11 + WSL](README_WIN_WSL.md)

## Other configs

### Neovim ⌨️

- [nvim-fredrik](nvim-fredrik/README.md)

### Git 🐙

- [Configure git](README_GIT.md)

### Project config/tooling 🧢

- [Configure projects](README_PROJECT.md)

### Fonts 💯

- [Berkeley Mono](https://berkeleygraphics.com/typefaces/berkeley-mono)
- [Maple Mono](https://github.com/subframe7536/maple-font)
- [Noto Color Emoji](https://fonts.google.com/noto/specimen/Noto+Color+Emoji)
- [Symbols Nerd Font Mono](https://github.com/ryanoasis/nerd-fonts)
