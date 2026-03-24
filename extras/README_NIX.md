# Nix

## Installation

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

## Nix management responsibilities

<details>
<summary>Repo structure</summary>

```txt
├── nix/                             # Nix configurations
│   ├── hosts/                       # Host-specific configurations
│   │   └── $host/                   # Individual host directory
│   │       ├── configuration.nix    # System settings
│   │       ├── hardware.nix         # Hardware config (optional, for NixOS)
│   │       └── users/
│   │           └── $username.nix    # User config
│   ├── lib/                         # Helper functions
│   │   ├── default.nix              # Library entry point
│   │   ├── systems.nix              # System configuration helpers
│   │   └── users.nix                # User configuration helpers
│   └── shared/                      # Shared configurations
│       ├── home/
│       │   ├── common.nix           # Cross-platform user packages
│       │   ├── darwin.nix           # macOS user config
│       │   └── linux.nix            # Linux user config
│       ├── overlays/
│       │   └── default.nix          # Overlay entry point
│       └── system/
│           ├── common.nix           # Cross-platform system packages
│           ├── darwin.nix           # macOS system config + Homebrew
│           └── linux.nix            # Linux system config
├── nvim-fredrik/                    # Neovim configuration
├── shell/                           # Shell configuration
│   ├── bin/                         # Custom shell scripts
│   ├── aliases.sh                   # Shell aliases
│   ├── exports.sh                   # Environment variables
│   └── sourcing.sh                  # Shell sourcing logic
├── stow/                            # GNU Stow dotfiles
├── extras/                          # One-off platform-specific extras and legacy configs
├── flake.nix                        # Nix flake configuration
└── rebuild.sh                       # Main rebuild script
```

</details>

### Components

| Component          | Tool                          | Scope       | Configuration Location                  |
| ------------------ | ----------------------------- | ----------- | --------------------------------------- |
| User dotfiles      | GNU Stow                      | Per-user    | `stow/`                                 |
| User packages      | home-manager                  | Per-user    | `nix/shared/home/`                      |
| User preferences   | home-manager                  | Per-user    | `nix/shared/home/` + host-specific      |
| Self-managed CLIs  | Native installers (curl/wget) | Per-user    | `nix/shared/home/self-managed-clis.nix` |
| Package tools      | bun (npm), uv (Python)        | Per-user    | `nix/shared/home/package-tools.nix`     |
| Host configuration | nix-darwin/NixOS              | System-wide | `nix/hosts/*/configuration.nix`         |
| System packages    | nix-darwin/NixOS              | System-wide | `nix/shared/system/`                    |
| System settings    | nix-darwin/NixOS              | System-wide | `nix/shared/system/`                    |
| Homebrew packages  | nix-darwin                    | System-wide | `nix/shared/system/darwin.nix`          |
| Package overlays   | Nix                           | System-wide | `nix/shared/overlays/`                  |

- NixOS configuration options:
  [stable](https://nixos.org/manual/nixos/stable/options) |
  [unstable](https://nixos.org/manual/nixos/unstable/options)
- [Home manager configuration options](https://nix-community.github.io/home-manager/options.xhtml)
- [nix-darwin configuration options](https://nix-darwin.github.io/nix-darwin/manual/index.html)

### Packages

| Package Type       | macOS System | macOS User | Linux System | Linux User |
| ------------------ | ------------ | ---------- | ------------ | ---------- |
| CLI tools          | Nix          | Nix        | Nix          | Nix        |
| GUI apps           | Homebrew     | Homebrew   | Nix          | Nix        |
| Mac App Store apps | Homebrew     | Homebrew   | -            | -          |
| Fonts              | Nix          | Nix        | Nix          | Nix        |

### Package sources

The intent here is to follow "unstable" sources on development machines, but
remain "stable" on e.g. production servers.

| Component    | macOS Source           | Linux Source    | Rationale                    |
| ------------ | ---------------------- | --------------- | ---------------------------- |
| nixpkgs      | nixpkgs-unstable       | nixpkgs (25.05) | macOS: latest, Linux: stable |
| home-manager | master (unstable)      | release-25.05   | macOS: latest, Linux: stable |
| nix-darwin   | master (uses unstable) | -               | Always latest features       |

Registry shortcuts:

```sh
# Stable packages
nix shell n#neovim

# Unstable packages
nix shell u#nodejs_22
```

## Troubleshooting

### Update stable vs unstable

By default, `./rebuild.sh` aims to be "reproducible" and uses the locked
`flake.lock`. Use `--update-unstable` to update Darwin-related inputs, or
`--update` to update all inputs.

```sh
# Update unstable/Darwin-related inputs + upgrade uv tools + upgrade bun packages
./rebuild.sh --update-unstable
# Or manually (flake inputs only): nix flake update nixpkgs-unstable nix-darwin home-manager-unstable dotfiles

# Update only stable/Linux-related inputs
nix flake update nixpkgs home-manager nixos-raspberrypi disko
```

### macOS permissions

If you get errors about `com.apple.universalaccess` or system settings during
nix-darwin activation:

1. **Grant Full Disk Access to your terminal:**
   - Open System Settings > Privacy & Security > Full Disk Access
   - Click + and add your terminal app (e.g.,
     `/Applications/Utilities/Terminal.app`)
   - Enable the checkbox for your terminal

### SSL certificate issues (when choosing upstream Nix)

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

### General troubleshooting

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
