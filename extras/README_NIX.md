# Nix config

Installing from scratch: [macOS](README_MACOS_INSTALL.md),
[NixOS](README_NIXOS_INSTALL.md), and the Raspberry Pi in
[its host README](../nix/hosts/rpi5-homelab/README.md).

## Nix management responsibilities

The layout is built for flexibility: each package or setting is declared once,
in the narrowest scope that covers every host that wants it, from every host
down to one host or one user. [nix/README.md](../nix/README.md) says which file
that is.

### Components

| Component          | Tool                            | Scope       | Configuration Location                  |
| ------------------ | ------------------------------- | ----------- | --------------------------------------- |
| User dotfiles      | GNU Stow                        | Per-user    | `stow/`                                 |
| User packages      | home-manager                    | Per-user    | `nix/shared/home/`                      |
| User preferences   | home-manager                    | Per-user    | `nix/shared/home/` + host-specific      |
| LLM agent CLIs     | llm-agents.nix flake input      | Per-user    | `nix/shared/home/llm-agents.nix`        |
| Host configuration | nix-darwin/NixOS                | System-wide | `nix/hosts/*/configuration.nix`         |
| System packages    | nix-darwin/NixOS                | System-wide | `nix/shared/system/`                    |
| System settings    | nix-darwin/NixOS                | System-wide | `nix/shared/system/`                    |
| Homebrew packages  | nix-darwin                      | System-wide | `nix/shared/system/darwin.nix`          |
| Package overlays   | Nix                             | System-wide | `nix/shared/overlays/`                  |

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
keep servers anchored to a single, deliberately updated version source. The
Raspberry Pi is anchored to the `nixos-raspberrypi` input: its nixpkgs,
home-manager (`home-manager-rpi`) and disko all follow the nixpkgs pinned by
that flake, so Darwin-motivated input updates cannot move the Pi, and kernel
builds hit the nixos-raspberrypi.cachix.org binary cache.

| Component    | macOS Source           | Raspberry Pi Source                       | Rationale                            |
| ------------ | ---------------------- | ----------------------------------------- | ------------------------------------ |
| nixpkgs      | nixpkgs-unstable       | nixos-raspberrypi's pin (nixos-25.11)     | macOS: latest, Pi: one version anchor |
| home-manager | master (unstable)      | release-25.11 (matches the pin)           | macOS: latest, Pi: one version anchor |
| nix-darwin   | master (uses unstable) | -                                         | Always latest features               |

The stable `nixpkgs` input (nixos-26.05) is only used for the Linux
formatters and the `n` registry shortcut — not for any system.

RPi bootloader note: `nixos-raspberrypi` deprecates `kernelboot` in favor
of the newer generational `kernel` bootloader. `rpi5-homelab` currently
sets `boot.loader.raspberry-pi.bootloader = "kernelboot-legacy-unsupported"`
to preserve the existing boot layout. Migrate to `kernel` only after checking
or resizing `/boot/firmware`: the `kernel` bootloader stores generations under
`/boot/firmware/nixos`, and upstream installer images use a 1024M firmware
partition while this host currently declares 512M in `hardware-configuration.nix`.

Registry shortcuts:

```sh
# Stable packages
nix shell n#neovim

# Unstable packages
nix shell u#nodejs_22
```

## Troubleshooting

### Update inputs

By default, rebuilding is "reproducible" and uses the locked `flake.lock`.
Update inputs explicitly, then rebuild:

```sh
# Update unstable/Darwin-related inputs, then rebuild
nix flake update nixpkgs-unstable nix-darwin home-manager-unstable llm-agents

# Update ALL inputs, then rebuild
nix flake update

# Update only Raspberry Pi-related inputs
nix flake update nixos-raspberrypi home-manager-rpi disko

# Update only the root stable nixpkgs (Linux formatters + the `n` registry
# shortcut; not used by any system configuration)
nix flake update nixpkgs
```

Homebrew is not covered by `flake.lock`. A rebuild only installs and removes
packages to match the declared set in `nix/shared/system/darwin.nix`; upgrading
is a separate, deliberate step:

```sh
brew update && brew upgrade   # add --greedy to also bump self-updating casks
```

When updating `nixos-raspberrypi`:

1. Verify that the re-locked `nixpkgs` node in `flake.lock` matches the rev
   pinned in nixos-raspberrypi's own `flake.lock` (Nix may re-resolve the
   branch head instead, which breaks binary cache hits for the kernel).
2. If their pin moved to a new NixOS release, bump the `home-manager-rpi`
   branch in `flake.nix` to the matching release.

### General troubleshooting

```sh
# Check configuration
nix flake check ~/.dotfiles

# Verbose rebuild
sudo nixos-rebuild switch --flake ~/.dotfiles --show-trace  # Linux
darwin-rebuild switch --flake ~/.dotfiles --show-trace      # macOS

# Clean cache
sudo nix-collect-garbage -d

# Rollback
sudo nixos-rebuild --rollback  # Linux
darwin-rebuild --rollback      # macOS
```
