# dotfiles 🍩

![screenshot](https://github.com/user-attachments/assets/ef833ca0-3d39-4a7c-94af-0f76afb96e6b)

These are my personal dotfiles. The setup is based on [nix](https://nixos.org)
(for reproducibility), [GNU Stow](https://www.gnu.org/software/stow/) (for
symlinking of dotfiles) and aims to be as idempotent as possible.

Nix configuration for hardware, system, and user packages. GNU Stow handles
dotfiles.

<details>
<summary>## Structure</summary>

```txt
nix/
├── hosts/           # Host-specific configurations
│   └── $host/       # Individual host directory
│       ├── configuration.nix    # System settings
│       ├── hardware.nix         # Hardware config (optional, for NixOS)
│       └── users/
│           └── $username.nix    # User config
├── lib/             # Helper functions
│   ├── default.nix    # Library entry point
│   └── helpers.nix    # mkDarwin, mkRpiNixos functions
└── shared/          # Shared configurations
    ├── users/
    │   └── default.nix        # Multi-user system
    ├── system/
    │   ├── common.nix         # Cross-platform system packages
    │   ├── darwin.nix         # macOS system config + Homebrew
    │   └── linux.nix          # Linux system config
    └── home/
        ├── common.nix         # Cross-platform user packages
        ├── darwin.nix         # macOS user config
        └── linux.nix          # Linux user config
```

</details>

<details>
<summary>## How It Works</summary>

The system uses helper functions in `lib/helpers.nix`:

- `mkDarwin`: Creates macOS configurations with nix-darwin + home-manager
- `mkRpiNixos`: Creates Raspberry Pi NixOS configurations

Each host imports shared modules:

- `shared/users/default.nix` - Multi-user configuration system
- `shared/system/` - Platform-specific system settings
- `shared/home/` - Platform-specific user settings

</details>

## Quick Start

```bash
# Daily rebuild
./rebuild.sh

# Update packages
./rebuild.sh --update

# Dotfiles only (no Nix rebuild)
./rebuild.sh --stow
```

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

## Setup

### Initial Installation

```bash
# Clone repo
git clone https://github.com/fredrikaverpil/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Install Nix
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Apply configuration
# Linux:
sudo nixos-rebuild switch --flake ~/.dotfiles#$(hostname)
# macOS (first time only):
sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake ~/.dotfiles#$(hostname)
```

### Daily Use

```bash
# Rebuild system + packages + dotfiles
./rebuild.sh

# Platform-specific commands
# Linux:
sudo nixos-rebuild switch --flake ~/.dotfiles
# macOS:
darwin-rebuild switch --flake ~/.dotfiles
```

## Troubleshooting

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

## Other READMEs and references

### Host-Specific Documentation

- [rpi5-homelab](nix/README_RPI5-HOMELAB.md)

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
