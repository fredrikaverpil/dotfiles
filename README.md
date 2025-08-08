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
<summary>Initial installation</summary>

> [!IMPORTANT]
>
> Make sure your terminal has full disk access on macOS before installing.

```sh
# Clone repo
git clone https://github.com/fredrikaverpil/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Install Nix (Determinate Systems installer - enables flakes by default, better uninstall,
# survives macOS updates, consistent installation across Linux/macOS)
# Choose "Determinate Nix" when prompted (performance optimized, better error messages)
# Learn more: https://determinate.systems/nix
# IMPORTANT: choose "no" during install, so to install upstream Nix.
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Set hostname to match a configuration in nix/hosts/
# macOS: sudo scutil --set HostName <hostname>
# Linux: sudo hostnamectl set-hostname <hostname>

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

### macOS Permissions

If you get errors about `com.apple.universalaccess` or system settings during
nix-darwin activation:

1. **Grant Full Disk Access to your terminal:**
   - Open System Settings > Privacy & Security > Full Disk Access
   - Click + and add your terminal app (e.g.,
     `/Applications/Utilities/Terminal.app`)
   - Enable the checkbox for your terminal

### SSL Certificate Issues (when choosing upstream Nix)

If you get SSL certificate errors after switching from Determinate to upstream
Nix:

```sh
# Fix broken certificate symlink
sudo rm /etc/ssl/certs/ca-certificates.crt
sudo ln -s /etc/ssl/cert.pem /etc/ssl/certs/ca-certificates.crt

# Clean up leftover Determinate configuration
sudo cp /etc/nix/nix.conf /etc/nix/nix.conf.backup
sudo tee /etc/nix/nix.conf << 'EOF'
extra-experimental-features = nix-command flakes
max-jobs = auto
ssl-cert-file = /etc/ssl/cert.pem
EOF
```

### General Troubleshooting

```sh
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

- [rpi5-homelab](nix/hosts/rpi5-homelab/README.md) - requires custom
  installation procedure

### Nix documentation references

- NixOS configuration options:
  [stable](https://nixos.org/manual/nixos/stable/options) |
  [unstable](https://nixos.org/manual/nixos/unstable/options)
- [Home manager configuration options](https://nix-community.github.io/home-manager/options.xhtml)
- [nix-darwin configuration options](https://nix-darwin.github.io/nix-darwin/manual/index.html)

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
