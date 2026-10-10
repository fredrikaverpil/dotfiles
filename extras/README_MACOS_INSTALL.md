# Installing on macOS from scratch

> [!IMPORTANT]
>
> Give the terminal Full Disk Access before starting (System Settings › Privacy
> & Security › Full Disk Access). nix-darwin writes system settings that need
> it.

```sh
# Homebrew. nix-darwin declares its packages but does not install it. This
# also installs the Xcode Command Line Tools, which bring git.
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

git clone https://github.com/fredrikaverpil/dotfiles.git ~/.dotfiles

# Upstream Nix, from the NixOS community installer. Open a new terminal after.
curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install --enable-flakes

# Must match a directory in nix/hosts/
sudo scutil --set HostName <hostname>

# First switch: nix-darwin, home-manager, Homebrew packages, and the stowed
# dotfiles
sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake ~/.dotfiles#<hostname>
```

Open a new terminal. `darwin-rebuild` is now on `PATH`,
and the [README](../README.md) takes over from here.

nix-darwin manages the Nix installation from the first switch on; the installer
only has to provide a working `nix`.

## Troubleshooting

### macOS permissions

If you get errors about `com.apple.universalaccess` or system settings during
nix-darwin activation:

1. **Grant Full Disk Access to your terminal:**
   - Open System Settings > Privacy & Security > Full Disk Access
   - Click + and add your terminal app (e.g.,
     `/Applications/Utilities/Terminal.app`)
   - Enable the checkbox for your terminal

### SSL certificate issues (after switching from Determinate Nix)

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
