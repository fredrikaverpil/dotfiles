# dotfiles 🐚

[![CI](https://github.com/fredrikaverpil/dotfiles/actions/workflows/build.yml/badge.svg)](https://github.com/fredrikaverpil/dotfiles/actions/workflows/build.yml)

**Introduction**

These are my personal dotfiles, for macOS, Windows and Linux. The setup is based on [dotbot](https://github.com/anishathalye/dotbot) and aims to be as idempotent as possible.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [macOS](#macos)
  - [Install dotfiles](#install-dotfiles)
  - [Optional installation](#optional-installation)
- [Windows 11 + WSL/Ubuntu](#windows-11--wslubuntu)
  - [Windows installations](#windows-installations)
  - [WSL/Ubuntu installations](#wslubuntu-installations)
  - [Configuration](#configuration)
    - [Windows Terminal settings](#windows-terminal-settings)
    - [WSL Tray](#wsl-tray)
    - [Set up HHKB for macOS-compatible workflow](#set-up-hhkb-for-macos-compatible-workflow)
  - [Closing notes](#closing-notes)
- [Ubuntu 20.04](#ubuntu-2004)
  - [Prerequisites](#prerequisites)
  - [Install dotfiles](#install-dotfiles-1)
  - [Optional installation](#optional-installation-1)
- [Extras](#extras)
  - [Clone all my public repos](#clone-all-my-public-repos)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## macOS

### Install dotfiles

Install:

```bash
mkdir -p code/repos && cd code/repos
git clone https://github.com/fredrikaverpil/dotfiles.git
cd dotfiles && ./install -vv
```

### Optional installation

Install Xcode commandline tools:

```bash
xcode-select --install
sudo xcodebuild -license accept
```

Install CLI and GUI apps:

```bash
installers/homebrew.sh
installers/zsh.sh
installers/starship.sh
installers/nerdfont.sh
installers/gh.sh
installers/python.sh

brew bundle --file=_macos/Brewfile
brew bundle --file=_macos/Brewfile_mas  # Requires having logged into the App Store
```

Terminal.app settings:

```bash
open _macos/terminal-ocean-dark.terminal
defaults write com.apple.terminal "Default Window Settings" "terminal-ocean-dark"
```

Custom key bindings for Swedish characters in US English layout:

```bash
ln -sf $(pwd)/_macos/DefaultKeyBinding.dict ~/Library/KeyBindings/DefaultKeyBinding.dict
```

Avoid creating .DS_Store files on network or USB volumes:

```bash
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
```

## Windows 11 + WSL/Ubuntu

This setup aims to run GUIs in Windows with all terminal and coding activities in WSL/Ubuntu.

### Windows installations

Run from administrative Powershell prompt:

```powershell
# Enable Hyper-V (for WSL)
Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart

# Install from ms store
winget install --accept-package-agreements --source msstore "Windows Subsystem for Linux" --id 9P9TQF7MRM4R
winget install --accept-package-agreements --source msstore "Ubuntu 20.04 LTS" --id 9N6SVWS3RX71
```

Start the Ubuntu prompt, create user.

Then install GUI apps (from [Microsoft Store](https://www.microsoft.com/en-us/store/apps/windows) and [winget-pkgs repo](https://github.com/microsoft/winget-pkgs)) in Windows from a Powershell prompt:

```powershell
# Coding
winget install --accept-package-agreements --source msstore "Windows Terminal" --id 9N0DX20HK701
winget install --accept-package-agreements --source msstore "Visual Studio Code" --id XP9KHM4BK9FZ7Q
winget install --accept-package-agreements --source winget "Docker Desktop" --id "Docker.DockerDesktop"

# HHKB/macOS compatible workflow
winget install --accept-package-agreements --source msstore "PureText" --id 9PKJV6319QTL
winget install --accept-package-agreements --source msstore "AutoHotkey Store Edition" --id 9NQ8Q8J78637
winget install --accept-package-agreements --source winget "SharpKeys" --id "RandyRants.SharpKeys"

# Other
winget install --accept-package-agreements --source winget "1Password" --id "AgileBits.1Password"
winget install --accept-package-agreements --source winget "Signal" --id "OpenWhisperSystems.Signal"
winget install --accept-package-agreements --source msstore "Spotify Music" --id 9NCBCSZSJRSB
winget install --accept-package-agreements --source msstore "Microsoft PowerToys" --id XP89DCGQ3K6VLD
```

### WSL/Ubuntu installations

From Ubuntu prompt:

```bash
mkdir -p code/repos && cd code/repos
git clone https://github.com/fredrikaverpil/dotfiles.git
cd dotfiles && ./install -vv
```

### Configuration

#### Windows Terminal settings

* Download and install [Fira Code Nerd font](https://github.com/ryanoasis/nerd-fonts/releases/) in Windows

Run from administrative Powershell prompt:

```powershell
# Remove original settings.json
rm $HOME\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json

# Create symlink into WSL2's dotfiles repo
cd \\wsl.localhost\Ubuntu-20.04\home\fredrik\code\repos\dotfiles
New-Item -ItemType SymbolicLink -Path $HOME\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json -Value _windows\terminal_settings.json
```

#### WSL Tray

* Download [WSL Tray](https://github.com/yzgyyang/wsl-tray/releases)
* Extract in `%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup`

#### Set up [HHKB](https://happyhackingkb.com/) for macOS-compatible workflow

Note: this assumes Autohotkey Sharpkeys and PureText are already installed.

* Install `autohotkey.ahk` by running this from a Powershell prompt:

```powershell
cp \\wsl.localhost\Ubuntu-20.04\home\fredrik\code\repos\dotfiles\_windows\autohotkey.ahk "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\autohotkey.ahk"
```

<details>
  <summary>Click here to see symlinking instructions</summary>

  Symlinking can be done, instead of copying the `autohotkey.ahk`, from an administrative Powershell prompt:

  ```powershell
  New-Item -ItemType SymbolicLink -Path "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\autohotkey.ahk" -Value _windows\autohotkey.ahk
  ```

  :warning: ...however, if WSL is not running, the AutoHotkey script won't run. It may be more desireable to copy the file into place.
</details>

* To override <kbd>Win (Left)</kbd> + <kbd>l</kbd>, launch Sharpkeys, load the `\\wsl.localhost\Ubuntu-20.04\home\fredrik\code\repos\dotfiles\_windows\sharpkeys.skl` file and write changes to the Registry.
* In PureText, remap (<kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>v</kbd>) to enable pasting of text without formatting.

### Closing notes

Reboot machine.

Proceed with reading more on the Ubuntu setup to install zsh, Python etc.

## Ubuntu 20.04

### Prerequisites

```bash
sudo apt update
sudo add-apt-repository universe
sudo apt upgrade
sudo apt install git curl unzip bash-completion
```

### Install dotfiles

```bash
mkdir -p code/repos && cd code/repos
git clone https://github.com/fredrikaverpil/dotfiles.git
cd dotfiles && ./install -vv
```

### Optional installation

```bash
installers/starship.sh
installers/nerdfont.sh
installers/zsh.sh  # remove the default prompt from ~/.zshrc after installation
installers/gh.sh
installers/python.sh
installers/docker.sh  # only if Docker Desktop in Windows was not installed
installers/snap-apps.sh
installers/nix.sh
```

## Extras

### Clone all my public repos

If more than 100 repos, change `PAGE` variable..

```bash
cd ~/code/repos
USER=fredrikaverpil; PAGE=1; curl "https://api.github.com/users/$USER/repos?page=$PAGE&per_page=100" | grep -e 'git_url*' | cut -d \" -f 4 | xargs -L1 git clone --recursive
```
