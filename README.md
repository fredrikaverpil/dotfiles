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
    - [PowerToys key remapping](#powertoys-key-remapping)
  - [Additional Windows apps](#additional-windows-apps)
  - [Additional Ubuntu/WSL apps](#additional-ubuntuwsl-apps)
- [Ubuntu 20.04](#ubuntu-2004)
  - [Install dotfiles](#install-dotfiles)
  - [Optional installation](#optional-installation)
- [To do](#to-do)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Windows 11 + WSL

This setup aims to run GUIs in Windows but terminal and coding defaults to WSL/Ubuntu.

### Enable WSL and install Windows GUI apps

From Powershell prompt:

```powershell
# Enable Hyper-V (for WSL)
Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart

# Install from ms store
winget install --source msstore "Windows Subsystem for Linux" --id 9P9TQF7MRM4R
winget install --source msstore "Ubuntu 20.04 LTS" --id 9N6SVWS3RX71
winget install --source msstore "Windows Terminal" --id 9N0DX20HK701
winget install --source msstore "Visual Studio Code" --id XP9KHM4BK9FZ7Q
```

### Install dotfiles in WSL/Ubuntu

From Ubuntu prompt:

```bash
# Install dotfiles
mkdir -p code/repos && cd code/repos
git clone https://github.com/fredrikaverpil/dotfiles.git
cd dotfiles && ./install -vv
```

### Configure Windows Terminal

* Download and install [Fira Code Nerd font](https://github.com/ryanoasis/nerd-fonts/releases/) in Windows
* Symlink Terminal settings via an Administrative Powershell prompt:

```powershell
# Remove original settings.json
rm $HOME\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json

# Create symlink into WSL2's dotfiles repo
New-Item -ItemType SymbolicLink -Path $HOME\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json -Value \\wsl.localhost\Ubuntu-20.04\home\fredrik\code\repos\dotfiles\_windows/terminal_settings.json
```

### Docker with WSL back-end

Install [Docker Desktop](https://hub.docker.com/editions/community/docker-ce-desktop-windows/) (enable WSL2 back-end)

### Set up HHKB for macOS-compatible workflow

Powershell prompt:

```powershell
winget install --source msstore  "AutoHotkey Store Edition" --id 9NQ8Q8J78637
winget install "SharpKeys" --id "RandyRants.SharpKeys"
```

Powershell prompt with administrative rights:

```powershell
cd \\wsl.localhost\Ubuntu-20.04\home\fredrik\code\repos\dotfiles
New-Item -ItemType SymbolicLink -Path "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\autohotkey.ahk" -Value _windows\autohotkey.ahk
```

Finally, launch Sharpkeys and load the `\\wsl.localhost\Ubuntu-20.04\home\fredrik\code\repos\dotfiles\_windows\sharpkeys.skl` file.

### Additional Windows apps

```powershell
winget install --source msstore  "Spotify Music" --id 9NCBCSZSJRSB
```

### Additional Ubuntu/WSL apps

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
