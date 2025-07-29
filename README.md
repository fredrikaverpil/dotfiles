# dotfiles 🍩

![screenshot](https://github.com/user-attachments/assets/ef833ca0-3d39-4a7c-94af-0f76afb96e6b)

Personal dotfiles using [Nix](https://nixos.org) for reproducible system/package
management and [GNU Stow](https://www.gnu.org/software/stow/) for dotfile
symlinking.

<details>
<summary>Repo structure</summary>

```txt
├── nix/             # Nix configurations
│   ├── hosts/       # Host-specific configurations
│   │   └── $host/   # Individual host directory
│   │       ├── configuration.nix    # System settings
│   │       ├── hardware.nix         # Hardware config (optional, for NixOS)
│   │       └── users/
│   │           └── $username.nix    # User config
│   ├── lib/         # Helper functions
│   │   ├── default.nix    # Library entry point
│   │   └── helpers.nix    # mkDarwin, mkRpiNixos functions
│   └── shared/      # Shared configurations
│       ├── users/
│       │   └── default.nix        # Multi-user system
│       ├── system/
│       │   ├── common.nix         # Cross-platform system packages
│       │   ├── darwin.nix         # macOS system config + Homebrew
│       │   └── linux.nix          # Linux system config
│       └── home/
│           ├── common.nix         # Cross-platform user packages
│           ├── darwin.nix         # macOS user config
│           └── linux.nix          # Linux user config
├── nvim-fredrik/    # Neovim configuration
│   ├── after/       # Filetype plugins and queries
│   ├── lua/fredrik/ # Main Neovim config modules
│   └── snippets/    # Code snippets
├── shell/           # Shell configuration
│   ├── bin/         # Custom shell scripts
│   ├── aliases.sh   # Shell aliases
│   ├── exports.sh   # Environment variables
│   └── sourcing.sh  # Shell sourcing logic
├── stow/            # GNU Stow dotfiles
│   ├── shared/      # Cross-platform dotfiles
│   ├── Darwin/      # macOS-specific dotfiles
│   └── Linux/       # Linux-specific dotfiles
└── extras/          # One-off platform-specific extras and legacy configs
```

</details>

## Quick Start

<details>
<summary>Initial installation</summary

```sh
# Clone repo
git clone https://github.com/fredrikaverpil/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Install Nix (Determinate Systems installer - enables flakes by default, better uninstall,
# survives macOS updates, consistent installation across Linux/macOS)
# Choose "Determinate Nix" when prompted
# Learn more: https://determinate.systems/nix
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Apply configuration
# Linux (NixOS):
sudo nixos-rebuild switch --flake ~/.dotfiles#$(hostname)

# macOS (first time only):
sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake ~/.dotfiles#$(hostname)

# After first-time setup, use the rebuild script:
./rebuild.sh
```

</details>

```sh
# Rebuild system + packages + dotfiles
./rebuild.sh

# Update flake inputs (nixpkgs, home-manager, etc.) then rebuild + dotfiles
./rebuild.sh --update

# Dotfiles only (no Nix rebuild)
./rebuild.sh --stow
```

<details>
<summary>Troubleshooting</summary>

```bash
# Check configuration
nix flake check ~/.dotfiles

# Verbose rebuild
sudo nixos-rebuild switch --flake ~/.dotfiles --show-trace  # Linux
darwin-rebuild switch --flake ~/.dotfiles --show-trace      # macOS

# Clean cache
nix-collect-garbage -d

# Rollback
sudo nixos-rebuild --rollback  # Linux
darwin-rebuild --rollback      # macOS
```

</details>

## Package Management

| Package Type       | macOS System | macOS User | Linux System | Linux User |
| ------------------ | ------------ | ---------- | ------------ | ---------- |
| CLI tools          | Nix          | Nix        | Nix          | Nix        |
| GUI apps           | Homebrew     | Homebrew   | Nix          | Nix        |
| Mac App Store apps | Homebrew     | Homebrew   | -            | -          |
| Fonts              | Nix          | Nix        | Nix          | Nix        |

## Dotfiles with GNU Stow

Dotfiles are managed with GNU Stow, not Nix:

- Edit files in `stow/` directory
- Changes are immediately active (no rebuild needed)
- Nix runs stow commands during home-manager activation

```bash
# Manual stow (if needed)
cd ~/.dotfiles/stow
stow --target="$HOME" --restow shared "$(uname -s)"
```

## Other READMEs and references

### Host-Specific Documentation

- [rpi5-homelab](nix/README_RPI5-HOMELAB.md) - requires custom installation
  procedure

### Non-Nix legacy docs

- [macOS](extras/darwin/README.md)
- [Windows 11 + WSL](extras/windows/README.md)

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
