# dotfiles 🐚

[![CI](https://github.com/fredrikaverpil/dotfiles/actions/workflows/build.yml/badge.svg)](https://github.com/fredrikaverpil/dotfiles/actions/workflows/build.yml)

## Prerequisites

### Windows 11

* Install Linux Subsystem for Windows [from Microsoft Store](https://www.microsoft.com/store/productId/9P9TQF7MRM4R)
* Enable Hyper-V (and restart):

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart`
```

* Install Ubuntu 20.04 [from Microsoft Store](https://www.microsoft.com/store/productId/9N6SVWS3RX71)
* Install [Docker Desktop](https://hub.docker.com/editions/community/docker-ce-desktop-windows/), to use in WSL2
* Download and install [Fira Code Nerd font](https://github.com/ryanoasis/nerd-fonts/releases/)
* Symlink Terminal settings via an Administrative Powershell prompt:

```powershell
# Remove original settings.json
rm $HOME\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json

# Create symlink into WSL2's dotfiles repo
New-Item -ItemType SymbolicLink -Path $HOME\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json -Value \\wsl.localhost\Ubuntu-20.04\home\fredrik\code\repos\dotfiles\_windows/terminal_settings.json
```

### Ubuntu (or WSL2)

```bash
sudo apt update
sudo apt upgrade
sudo apt install git
```

## Installation

```bash
git clone https://github.com/fredrikaverpil/dotfiles.git
./install -vv
```

## Optional installation

### Ubuntu

```bash
installers/python.sh
installers/docker.sh
installers/snap-apps.sh
installers/nix.sh
installers/homebrew.sh  # experimental!
installers/zsh.sh  # edit out the default prompt from ~/.zshrc after installation
```

## To do

* improve this README (add note on setup being idempotent)
* bring back details from old README
* move macOS setup into dotbot.
