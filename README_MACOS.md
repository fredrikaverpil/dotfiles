## macOS 🍎

> [!NOTE]
>
> **For machines managed with Nix (recommended)**, see
> [nix/README.md](nix/README.md). The instructions below are maintained for
> legacy/manual setups - refer to the Nix configuration for the canonical
> package list.

### Install dotfiles

```bash
git clone --recursive https://github.com/fredrikaverpil/dotfiles.git ~/.dotfiles
cd .dotfiles && stow/symlink.sh
```

> [!NOTE]
>
> See [README_GIT.md](README_GIT.md) for details on setting up git.

### Install tooling

Install Xcode commandline tools:

```bash
xcode-select --install
sudo xcodebuild -license accept
```

Install [Homebrew](https://brew.sh/) and [pkgx](https://pkgx.sh):

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install pkgxdev/made/pkgx
```

<details>
  <summary>🎶 Expand for x86 support.</summary>

When on an arm64 device, homebrew is installed in `/opt/homebrew/bin/brew`. You
can install an x64 version in `/usr/local/bin/brew`. See
[installers/homebrew.sh](installers/homebrew.sh) for more info.

</details>

### Install apps

```bash
# Note: Brewfiles are now empty - manually add desired packages from the Nix configuration:
# - CLI tools: nix/shared/home-manager-base.nix
# - GUI apps: nix/shared/darwin/homebrew.nix (casks and brews sections)
# - Host-specific: nix/hosts/*/darwin-configuration.nix
# - Mac App Store apps: nix/shared/darwin/homebrew.nix (masApps section)

brew bundle --file=_macos/Brewfile
brew bundle --file=_macos/Brewfile_mas  # requires being logged into the App Store
```

Execute desired installers:

```bash
installers/neovim-distros.sh
installers/neovim.sh --nightly

# run LazyVim
NVIM_APPNAME=fredrik nvim

# or run custom nvim config
nvim
```

### OS configuration

```bash
_macos/set_defaults.sh
_macos/set_hostname.sh $DESIRED_HOSTNAME
```

#### System settings

- Open up 9 Desktops in Mission control.
- Disable/enable in Keyboard → Keyboard shortcuts → Mission Control:
  - [ ] Mission control
    - [ ] Mission Control
    - [ ] Application windows
    - [ ] Move left a space
    - [ ] Move right a space
    - [x] Switch to Desktop 1
    - ...
    - [x] Switch to Desktop 9
- Mission control related in Desktop & Dock → Mission Control:
  - [ ] Automatically rearrange Spaces based on most recent use.
  - [ ] Shortcuts: Mission control keyboard shortcut
  - Hot corners:
    - Upper left: Mission Control
    - Upper right: Desktop
    - Lower left: Lock screen
    - Lower right: Quick note
- Accessibility:
  - Display:
    - [ ] Reduce motion.
- Keyboard
  - Key repeat rate: fast
  - Delay until repeat: short
  - Dictation:
    - Shortcut: Press (mic symbol)
  - Shortcuts:
    - Keyboard shortcuts:
      - Input sources:
        - Untick the shortcut for ^Space (Ctrl+Space).
