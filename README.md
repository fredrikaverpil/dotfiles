# dotfiles 🐚

[![CI](https://github.com/fredrikaverpil/dotfiles/actions/workflows/build.yml/badge.svg)](https://github.com/fredrikaverpil/dotfiles/actions/workflows/build.yml)

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [Windows 11 + WSL/Ubuntu](#windows-11--wslubuntu)
  - [Windows installations](#windows-installations)
  - [WSL/Ubuntu installations](#wslubuntu-installations)
  - [Configuration](#configuration)
    - [Windows Terminal settings](#windows-terminal-settings)
    - [WSL Tray](#wsl-tray)
    - [Set up HHKB for macOS-compatible workflow](#set-up-hhkb-for-macos-compatible-workflow)
  - [Closing notes](#closing-notes)
- [Ubuntu 20.04](#ubuntu-2004)
  - [Install dotfiles](#install-dotfiles)
  - [Optional installation](#optional-installation)
- [To do](#to-do)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

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
winget install --accept-package-agreements --source msstore  "AutoHotkey Store Edition" --id 9NQ8Q8J78637
winget install --accept-package-agreements --source winget "SharpKeys" --id "RandyRants.SharpKeys"

# Other
winget install --accept-package-agreements --source winget "1Password" --id "AgileBits.1Password"
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

Note: this assumes Autohotkey and Sharpkeys are already installed.

Run from administrative Powershell prompt:

```powershell
cd \\wsl.localhost\Ubuntu-20.04\home\fredrik\code\repos\dotfiles
New-Item -ItemType SymbolicLink -Path "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\autohotkey.ahk" -Value _windows\autohotkey.ahk
```

Launch Sharpkeys, load the `\\wsl.localhost\Ubuntu-20.04\home\fredrik\code\repos\dotfiles\_windows\sharpkeys.skl` file, write changes to the Registry and reboot.

### Closing notes

Reboot machine.

Proceed with reading more on the Ubuntu setup to install zsh, Python etc.

## Ubuntu 20.04

```bash
sudo apt update
sudo apt upgrade
sudo apt install git
```

### Install dotfiles

```bash
mkdir -p code/repos && cd code/repos
git clone https://github.com/fredrikaverpil/dotfiles.git
cd dotfiles && ./install -vv
```

### Optional installation

```bash
installers/python.sh
installers/docker.sh  # only if Docker Desktop in Windows was not installed
installers/snap-apps.sh
installers/nix.sh
installers/homebrew.sh  # experimental!
installers/zsh.sh  # edit out the default prompt from ~/.zshrc after installation
```

## To do

* improve this README (add note on setup being idempotent)
* bring back details from old README
* move macOS setup into dotbot.
