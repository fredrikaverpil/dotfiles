# dotfiles 🐚

[![CI](https://github.com/fredrikaverpil/dotfiles/actions/workflows/build.yml/badge.svg)](https://github.com/fredrikaverpil/dotfiles/actions/workflows/build.yml)

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [Windows 11 + WSL](#windows-11--wsl)
  - [Enable WSL and install Windows GUI apps](#enable-wsl-and-install-windows-gui-apps)
  - [Install dotfiles in WSL/Ubuntu](#install-dotfiles-in-wslubuntu)
  - [Configure Windows Terminal](#configure-windows-terminal)
  - [Docker with WSL back-end](#docker-with-wsl-back-end)
  - [Set up HHKB for macOS-compatible workflow](#set-up-hhkb-for-macos-compatible-workflow)
  - [Additional Windows apps](#additional-windows-apps)
  - [Additional Ubuntu/WSL apps](#additional-ubuntuwsl-apps)
- [Ubuntu 20.04](#ubuntu-2004)
  - [Install dotfiles](#install-dotfiles)
  - [Optional installation](#optional-installation)
- [To do](#to-do)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Windows 11 + WSL

This setup aims to run GUIs in Windows with all terminal and coding activities in WSL/Ubuntu.

### Install WSL and GUI apps

Run from administrative Powershell prompt:

```powershell
# Enable Hyper-V (for WSL)
Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart

# Install from ms store
winget install --accept-package-agreements --source msstore "Windows Subsystem for Linux" --id 9P9TQF7MRM4R
winget install --accept-package-agreements --source msstore "Ubuntu 20.04 LTS" --id 9N6SVWS3RX71
```

Start the Ubuntu prompt, create user.

### Install Windows GUI apps

```powershell
# Coding
winget install --accept-package-agreements --source msstore "Windows Terminal" --id 9N0DX20HK701
winget install --accept-package-agreements --source msstore "Visual Studio Code" --id XP9KHM4BK9FZ7Q
winget install --accept-package-agreements --source winget "Docker Desktop" --id "Docker.DockerDesktop"

# HHKB/macOS compatible workflow
winget install --accept-package-agreements --source msstore  "AutoHotkey Store Edition" --id 9NQ8Q8J78637
winget install --accept-package-agreements "SharpKeys" --id "RandyRants.SharpKeys"

# Other
winget install --accept-package-agreements "1Password" --id "AgileBits.1Password"
winget install --accept-package-agreements --source msstore "Spotify Music" --id 9NCBCSZSJRSB
winget install --accept-package-agreements --source msstore "Adobe Reader Touch" --id 9WZDNCRFJ2GC
```

### Install dotfiles in WSL/Ubuntu

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
New-Item -ItemType SymbolicLink -Path $HOME\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json -Value \\wsl.localhost\Ubuntu-20.04\home\fredrik\code\repos\dotfiles\_windows/terminal_settings.json
```

#### Set up HHKB for macOS-compatible workflow

Note: Autohotkey and Sharpkeys should have been installed via `winget.ps1`.

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
