# dotfiles 🐚

[![CI](https://github.com/fredrikaverpil/dotfiles/actions/workflows/build.yml/badge.svg)](https://github.com/fredrikaverpil/dotfiles/actions/workflows/build.yml)

## Windows 11 + WSL

* Install Linux Subsystem for Windows [from Microsoft Store](https://www.microsoft.com/store/productId/9P9TQF7MRM4R)
* Enable Hyper-V from Powershell prompt (and restart):

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
```

* Install Ubuntu 20.04 [from Microsoft Store](https://www.microsoft.com/store/productId/9N6SVWS3RX71)
* Install dotfiles in WSL/Ubuntu, using the Ubuntu prompt:

```bash
mkdir -p code/repos && cd code/repos
git clone https://github.com/fredrikaverpil/dotfiles.git
cd dotfiles && ./install -vv
```

* Install Windows Terminal [from Microsoft Store](https://www.microsoft.com/store/productId/9N0DX20HK701)
* Download and install [Fira Code Nerd font](https://github.com/ryanoasis/nerd-fonts/releases/) in Windows
* Symlink Terminal settings via an Administrative Powershell prompt:

```powershell
# Remove original settings.json
rm $HOME\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json

# Create symlink into WSL2's dotfiles repo
New-Item -ItemType SymbolicLink -Path $HOME\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json -Value \\wsl.localhost\Ubuntu-20.04\home\fredrik\code\repos\dotfiles\_windows/terminal_settings.json
```

* Install [Docker Desktop](https://hub.docker.com/editions/community/docker-ce-desktop-windows/) to be used in WSL/Ubuntu

* Download and install 64-bit [Visual Studio Code](https://code.visualstudio.com/Download) in Windows

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
