# Nix Configuration

This directory contains a comprehensive Nix-based system configuration for both
Linux (NixOS) and macOS (darwin) systems using home-manager and
platform-specific tools.

## Architecture Overview

The configuration follows a modular approach with clear separation between
shared and host-specific settings:

```txt
nix/
├── hosts/           # Host-specific configurations
│   ├── zap/         # Apple Silicon, macOS
│   ├── plumbus/     # Apple Silicon, macOS
│   └── rpi5-homelab/ # Raspberry Pi 5, NixOS
├── shared/          # Shared configurations
│   ├── shell/       # Shell-specific configs (aliases, exports)
│   ├── darwin-system.nix        # Core macOS system settings
│   ├── homebrew.nix             # Homebrew package management
│   ├── home-manager-base.nix    # Cross-platform home-manager foundation
│   ├── home-manager-darwin.nix  # macOS-specific home-manager config
│   └── home-manager-linux.nix   # Linux-specific home-manager config
└── scripts/         # Installation and maintenance scripts
```

## Host-Specific documentation

- [rpi5-homelab](README_RPI5-HOMELAB.md)

## Hybrid Configuration Strategy

This setup uses a multi-layered approach combining different tools for optimal
flexibility and productivity:

### Dotfile Management: Dotbot

**Why Dotbot instead of Nix for dotfiles?**

While Nix can manage dotfiles declaratively, this setup uses
[dotbot](https://github.com/anishathalye/dotbot) for symlinking dotfiles
because:

- **Rapid iteration**: Edit dotfiles and see changes immediately without
  rebuilding
- **No rebuild overhead**: Avoid rebuild commands for simple config tweaks
- **Familiar workflow**: Traditional dotfile editing experience
- **Fallback compatibility**: Works even when Nix is unavailable

**How it works:**

- Nix automatically runs `./install` (dotbot) during home-manager activation
- Dotbot creates symlinks from `~/.dotfiles/` to `~/` (e.g., `gitconfig` →
  `~/.gitconfig`)
- Edit dotfiles directly in the repo - changes are immediately active
- Nix manages packages and system settings, dotbot handles file symlinking

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
~/.dotfiles/nix/scripts/switch.sh --update
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
