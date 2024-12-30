## macOS 🍎

### Install dotfiles

```bash
git clone --recursive https://github.com/fredrikaverpil/dotfiles.git ~/.dotfiles
cd .dotfiles && ./install -vv
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
brew bundle --file=_macos/Brewfile
brew bundle --file=_macos/Brewfile_mas  # requires being logged into the App Store
```

Execute desired installers:

```bash
installers/neovim-distros.sh
installers/neovim-nightly.sh

# run LazyVim
NVIM_APPNAME=LazyVim nvim

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
