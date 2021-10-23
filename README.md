# dotfiles 🐚

[![CI](https://github.com/fredrikaverpil/dotfiles/actions/workflows/build.yml/badge.svg)](https://github.com/fredrikaverpil/dotfiles/actions/workflows/build.yml)

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

```powershell
winget install --source msstore  "Microsoft PowerToys" --id XP89DCGQ3K6VLD
```

* In the Keyboard Manager, remap `Win Left` to `Ctrl`.
* In PowerToys Run, remap shortcut to `Ctrl` `Space`.

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
