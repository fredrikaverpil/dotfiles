# Nix Configuration

This directory contains a comprehensive Nix-based system configuration for both
Linux (NixOS) and macOS (darwin) systems using home-manager and
platform-specific tools.

## Architecture Overview

The configuration follows a modular approach with clear separation between
shared and host-specific settings, using a consistent structure across all platforms:

```txt
nix/
├── hosts/           # Host-specific configurations
│   ├── zap/         # Apple Silicon, macOS
│   │   ├── configuration.nix    # System-level settings
│   │   └── home.nix             # User-level home-manager config (optional)
│   ├── plumbus/     # Apple Silicon, macOS
│   │   ├── configuration.nix    # System-level settings
│   │   └── home.nix             # User-level home-manager config (optional)
│   └── rpi5-homelab/ # Raspberry Pi 5, NixOS
│       ├── configuration.nix    # System-level settings
│       ├── hardware.nix         # Hardware-specific config
│       └── home.nix             # User-level home-manager config
├── lib/             # Helper functions for building configurations
│   ├── default.nix    # Entrypoint for the library
│   └── helpers.nix    # Helper functions (e.g., mkDarwin)
├── shared/          # Shared configurations
│   ├── shell/       # Shell-specific configs (aliases, exports)
│   ├── system/
│   │   ├── common.nix         # Cross-platform system packages & config
│   │   ├── darwin.nix         # macOS system configuration
│   │   └── linux.nix          # Linux system configuration (future)
│   ├── darwin/
│   │   └── homebrew.nix             # Homebrew package management
│   ├── home/
│   │   ├── common.nix         # Cross-platform home-manager config
│   │   ├── darwin.nix         # macOS-specific home-manager config
│   │   └── linux.nix          # Linux-specific home-manager config
```

### Consistent Host Architecture

All hosts follow the same architectural pattern for maintainability:

- **`configuration.nix`**: System-level settings (services, system packages, platform-specific configurations)
- **`home.nix`**: User-level settings (user packages, dotfiles, personal configurations)
- **Platform-specific files**: Additional files as needed (e.g., `hardware.nix` for NixOS)

This consistent structure provides:
- **Clear separation of concerns** between system and user configuration
- **Easy maintenance** across different platforms
- **Predictable organization** when adding new hosts
- **Modular configuration** that imports shared components

### Configuration Flow

Each host's configuration follows this import hierarchy:

**macOS hosts (zap, plumbus):**
```
flake.nix
└── lib.mkDarwin
    ├── inputs.home-manager-unstable.darwinModules.home-manager
    ├── ../../shared/system/darwin.nix     # macOS system settings
    ├── ../../shared/system/common.nix   # Common packages
    ├── ./configuration.nix                # Host-specific system config
    └── ./home.nix (optional)              # Host-specific user config
```

**Linux hosts (rpi5-homelab):**
```
configuration.nix
├── ./hardware.nix                     # Hardware-specific settings
├── ./home.nix                         # Host-specific user config
│   └── ../../shared/home/linux.nix   # Shared Linux user config
└── home-manager.nixosModules.home-manager
```

## Host-Specific documentation

- [rpi5-homelab](README_RPI5-HOMELAB.md)

## Hybrid Configuration Strategy

This setup uses a multi-layered approach combining different tools for optimal
flexibility and productivity:

### Dotfile Management: GNU Stow

**Why Stow instead of Nix for dotfiles?**

While Nix can manage dotfiles declaratively, this setup uses
[GNU Stow](https://www.gnu.org/software/stow/) for symlinking dotfiles because:

- **Rapid iteration**: Edit dotfiles and see changes immediately without
  rebuilding
- **No rebuild overhead**: Avoid rebuild commands for simple config tweaks
- **Familiar workflow**: Traditional dotfile editing experience
- **Fallback compatibility**: Works even when Nix is unavailable
- **Simple and reliable**: Battle-tested tool with minimal dependencies

**How it works:**

- Nix automatically runs `./symlink.sh` (stow) during home-manager activation
- Stow creates symlinks from `~/.dotfiles/stow/` to `~/` (e.g.,
  `stow/shared/.gitconfig` → `~/.gitconfig`)
- Edit dotfiles directly in the repo - changes are immediately active
- Nix manages packages and system settings, stow handles file symlinking

## Workflow Guide

### When to Use Each Approach

| Scenario            | Command                                     | What It Does | Use Case                                                               |
| ------------------- | ------------------------------------------- | ------------ | ---------------------------------------------------------------------- |
| **Daily rebuilds**  | `./rebuild.sh`                              | Nix + Stow (system + packages + dotfiles) | After changing Nix configurations, adding packages, or system settings |
| **Package updates** | `./rebuild.sh --update`                     | Update flake inputs + Nix + Stow | Monthly maintenance, updating to latest package versions               |
| **Stow-only mode** | `./rebuild.sh --stow`                       | Stow only (dotfiles only) | Testing, minimal setups, or Nix-free environments                  |
| **Direct Stow**     | `stow/symlink.sh`                           | Stow only (dotfiles only) | Legacy systems, minimal setups, or when only dotfiles are needed       |
| **Manual control**  | `darwin-rebuild switch --flake ~/.dotfiles` | Nix + Stow (manual) | Debugging, advanced options, or CI/CD pipelines                        |

### Typical Workflows

**New machine setup:**

1. Install Nix → Clone repo → Run initial `sudo nix run nix-darwin` command
2. Daily use: `./rebuild.sh` (rebuilds system + packages + dotfiles)

**Dotfile-only changes:**

- Edit files in `stow/` directory → Changes are immediately active (no rebuild needed)

**System/package changes:**

- Edit Nix files → Run `./rebuild.sh` → Rebuilds system + packages + dotfiles

**Emergency/testing:**

- Use `./rebuild.sh --stow` → Only updates dotfiles (bypasses Nix entirely)

## Package Management Strategy

### Cross-platform Nix Packages

Use Nix for:

- ✅ CLI development tools (git, gh, ripgrep, fd)
- ✅ Programming language toolchains (rustup, uv)
- ✅ Shell enhancements (starship, zoxide, eza)
- ✅ Cross-platform utilities (jq, curl, wget)
- ✅ Development databases (postgresql, mysql)

**Advantages**: Reproducible, version-controlled, rollback capability

### Platform-Specific Package Managers

#### Linux (NixOS)

- **System packages**: Managed through NixOS configuration
- **User packages**: Managed through home-manager
- **Services**: Declaratively configured via NixOS modules

#### macOS (Darwin)

- **Homebrew**: Used for GUI applications and macOS-specific integrations
  - 🍺 GUI applications (Ghostty, VSCode, Spotify)
  - 🍺 macOS-specific integrations (fonts, system extensions)
  - 🍺 Packages from custom taps not in nixpkgs
  - 🍺 Mac App Store applications

### Decision Criteria

| Criteria                    | Nix                  | Platform-Specific  |
| --------------------------- | -------------------- | ------------------ |
| CLI tools                   | ✅ Preferred         | ❌ Avoid           |
| GUI applications            | ❌ Limited support   | ✅ Preferred       |
| Custom/proprietary software | ❌ Often unavailable | ✅ Better coverage |
| System integration          | ❌ Can be complex    | ✅ Native          |
| Reproducibility             | ✅ Excellent         | ❌ Limited         |
| Version control             | ✅ Declarative       | ❌ Imperative      |

## Platform Setup

### Installation

**Prerequisites for macOS (Darwin):**

- macOS system (Intel or Apple Silicon)
- Xcode Command Line Tools installed
- Administrator privileges

#### Initial Setup

```bash
# Clone the dotfiles repository
git clone https://github.com/fredrikaverpil/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Install Nix using Determinate Systems installer
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Apply configuration (specify hostname on first install only)
# Linux/NixOS:
sudo nixos-rebuild switch --flake ~/.dotfiles#$(hostname)
# macOS/Darwin (requires sudo and experimental features for initial system activation):
sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake ~/.dotfiles#$(hostname)
```

> [!NOTE]
>
> **macOS Initial Setup Requirements**:
>
> - The `--extra-experimental-features` flag is required for initial setup only
> - The first-time setup with `sudo` will show a warning about `$HOME` ownership
>   (`$HOME ('/Users/username') is not owned by you, falling back to the one defined in the 'passwd' file ('/var/root')`).
>   This is expected behavior and can be safely ignored.
> - If you get "Unexpected files in /etc" error, backup the existing file, as
>   noted below:

```bash
sudo mv /etc/nix/nix.conf /etc/nix/nix.conf.before-nix-darwin>
```

**Why
[Determinate Nix](https://determinate.systems/posts/determinate-nix-installer/)?**

**For macOS:**

- **Better macOS integration**: Handles system updates and SIP restrictions
- **Automatic uninstallation**: Clean removal when needed
- **Improved reliability**: More robust than official installer on macOS
- **Active maintenance**: Regular updates for macOS compatibility

**For Linux:**

- **Consistent experience**: Same installer across all platforms
- **Better defaults**: Includes flakes and other modern features enabled
- **Reliable installation**: More robust than official installer
- **Automatic uninstallation**: Clean removal support

#### Configuration Management

**Using the rebuild.sh script (recommended):**

```bash
# Basic rebuild (auto-detects platform and hostname)
./rebuild.sh

# Update flake inputs and rebuild
./rebuild.sh --update

# Use Stow-only mode (bypass Nix)
./rebuild.sh --stow

# Show help and available options
./rebuild.sh --help
```

**Using platform-specific commands directly:**

```bash
# Apply configuration changes (hostname auto-detected)
# Linux/NixOS:
sudo nixos-rebuild switch --flake ~/.dotfiles
# macOS/Darwin (sudo still required for system activation):
sudo darwin-rebuild switch --flake ~/.dotfiles

# Deploy remotely from another machine (Linux only)
nixos-rebuild switch --flake ~/.dotfiles#hostname --target-host user@hostname.local
```

> [!NOTE]
>
> Rebuilds are not required when only changing the symlinked dotfiles.

#### Troubleshooting

```bash
# Verbose rebuild with error details
# Linux/NixOS:
sudo nixos-rebuild switch --flake ~/.dotfiles --show-trace
# macOS/Darwin:
darwin-rebuild switch --flake ~/.dotfiles --show-trace

# Clean build cache (both platforms)
nix-collect-garbage -d

# Check configuration syntax (both platforms)
nix flake check ~/.dotfiles

# Platform-specific troubleshooting
# Linux: Check system status
systemctl status
# macOS: Reset Homebrew state (if issues occur)
brew cleanup
brew doctor
```

#### Rollbacks

```bash
# List available generations
# Linux/NixOS:
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
# macOS/Darwin:
darwin-rebuild --list-generations

# Rollback to previous generation
# Linux/NixOS:
sudo nixos-rebuild --rollback
# macOS/Darwin:
darwin-rebuild --rollback

# Linux only: Select generation from GRUB menu on boot
```

## Shared Operations

Commands that work the same way on both Linux and macOS platforms (but only
affect the current host).

### Updates and Maintenance

#### Updating Configurations

```bash
# Update flake inputs (gets latest package versions)
nix flake update ~/.dotfiles

# Apply updates on Linux/NixOS
sudo nixos-rebuild switch --flake ~/.dotfiles

# Apply updates on macOS/Darwin
darwin-rebuild switch --flake ~/.dotfiles

# Convenience script that combines update + rebuild
~/.dotfiles/rebuild.sh --update
```

#### Configuration Validation

```bash
# Check configuration syntax and dependencies
nix flake check ~/.dotfiles

# Check specific host configuration
nix flake check ~/.dotfiles#hostname

# Dry-run to see what would change (NixOS)
sudo nixos-rebuild dry-run --flake ~/.dotfiles

# Dry-run to see what would change (macOS)
darwin-rebuild check --flake ~/.dotfiles
```

### Common Troubleshooting

#### Build Failures

```bash
# Clean build cache
nix-collect-garbage -d

# Verbose rebuild with error details (Linux)
sudo nixos-rebuild switch --flake ~/.dotfiles --show-trace

# Verbose rebuild with error details (macOS)
darwin-rebuild switch --flake ~/.dotfiles --show-trace
```

#### Network Issues

```bash
# Test internet connectivity
ping google.com

# Check DNS resolution
nslookup github.com

# Restart network services (Linux)
sudo systemctl restart systemd-networkd

# Check network status (Linux)
systemctl status systemd-networkd
```

#### Permission Issues

```bash
# Fix Nix store permissions
sudo chown -R root:nixbld /nix

# Restart Nix daemon
sudo systemctl restart nix-daemon

# Check Nix daemon status
systemctl status nix-daemon
```

#### macOS HOME Ownership Warning

During initial nix-darwin setup, you may see this warning:

```
warning: $HOME ('/Users/username') is not owned by you, falling back to the one defined in the 'passwd' file ('/var/root')
```

**This is expected behavior** when running the initial setup with `sudo`. The
warning occurs because:

- Initial system activation requires root privileges (`sudo`)
- Running with `sudo` changes `$HOME` from `/Users/username` to `/var/root`
- nix-darwin detects this and falls back to the correct user home directory

**Solution**: This warning can be safely ignored during initial setup. After the
first successful run, use `darwin-rebuild switch --flake ~/.dotfiles` (without
`sudo`) for subsequent rebuilds.
