## Windows 11 + WSL

⚠️ These instructions are likely to become outdated, as my primary system is
macOS.

This setup aims to run GUIs in Windows with all terminal and coding activities
in WSL/Ubuntu.

🎒 Pro tip: set up WSL/Ubuntu, Wezterm, dotfiles repo and homebrew first.

### Windows installations

<details>
  <summary>Click here for instructions in older Windows 10</summary>

```powershell
# prerequisites
Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
wsl --install
wsl --list --online

# reboot!

# if wsl installed "Ubuntu":
wsl --terminate Ubuntu
wsl --unregister Ubuntu

# install!
wsl --install --distribution Ubuntu

# get winget by downloading "App Installer" from the Microsoft Store:
# https://www.microsoft.com/en-us/p/app-installer/9nblggh4nns1
```

</details>

Run from administrative Powershell prompt:

```powershell
# Enable Hyper-V (for WSL)
Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart

# Install from ms store
winget install --accept-package-agreements --accept-source-agreements --source msstore "Windows Subsystem for Linux" --id 9P9TQF7MRM4R
winget install --accept-package-agreements --source msstore "Ubuntu" --id 9PDXGNCFSCZV
```

Start the Ubuntu prompt, create user.

Then install GUI apps (from
[Microsoft Store](https://www.microsoft.com/en-us/store/apps/windows) and
[winget-pkgs repo](https://github.com/microsoft/winget-pkgs)) in Windows from a
Powershell prompt:

```powershell
# Coding
winget install wez.wezterm  # or maybe just install via setup.exe installer...?
# winget install --accept-package-agreements --source msstore "Windows Terminal" --id 9N0DX20HK701
winget install --accept-package-agreements --source msstore "Visual Studio Code" --id XP9KHM4BK9FZ7Q
winget install --accept-package-agreements --source winget "Docker Desktop" --id "Docker.DockerDesktop"
winget install --accept-package-agreements --source msstore "Slack" --id "9WZDNCRDK3WP"

# HHKB/macOS compatible workflow
winget install --accept-package-agreements --source msstore "PureText" --id 9PKJV6319QTL
winget install --accept-package-agreements --source msstore "AutoHotkey Store Edition" --id 9NQ8Q8J78637
winget install --accept-package-agreements --source winget "SharpKeys" --id "RandyRants.SharpKeys"

# Other
winget install --accept-package-agreements --source winget "1Password" --id "AgileBits.1Password"
winget install --accept-package-agreements --source winget "Signal" --id "OpenWhisperSystems.Signal"
winget install --accept-package-agreements --source msstore "Spotify Music" --id 9NCBCSZSJRSB
winget install --accept-package-agreements --source msstore "Auto Dark Mode" --id XP8JK4HZBVF435
```

### Clone down dotfiles into WSL

From the Ubuntu prompt:

```bash
git clone --recursive https://github.com/fredrikaverpil/dotfiles.git ~/.dotfiles
cd .dotfiles && ./rebuild.sh --stow
```

<details>
  <summary>🔧 Advanced: Direct stow usage</summary>

For direct control over stow operations:

```bash
# Use the install script (recommended)
cd ~/.dotfiles/stow && ./install.sh

# Manual stow commands
cd ~/.dotfiles/stow
stow --target="$HOME" --restow shared "$(uname -s)"  # Dynamic platform detection
```

</details>

> [!NOTE] See [README_GIT.md](../README_GIT.md) for details on setting up git.

### Windows configuration

#### Wezterm

From administrative Powershell prompt:

```powershell
cd \\wsl.localhost\Ubuntu\home\fredrik\code\dotfiles

New-Item -ItemType SymbolicLink -Path $HOME\.wezterm.lua -Value wezterm.lua
```

Restart wezterm, and it should now start up straight into Ubuntu.

#### WSL Configuration

Create `~/.wslconfig` in your Windows user directory to limit WSL memory usage:

```ini
# https://learn.microsoft.com/en-us/windows/wsl/wsl-config

# Limits VM memory
memory=2GB
```

🎒 To get set up more quickly, skip over onto the Ubuntu configuration.

<details>
  <summary>Click here for old notes on the Windows Terminal.</summary>

#### Windows Terminal

Run from administrative Powershell prompt:

```powershell
# Remove original settings.json
rm $HOME\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json

# Create symlink into WSL2's dotfiles repo
cd \\wsl.localhost\Ubuntu\home\fredrik\code\dotfiles

New-Item -ItemType SymbolicLink -Path $HOME\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json -Value _windows\terminal_settings.json
```

</details>

#### WSL Tray

- Download [WSL Tray](https://github.com/yzgyyang/wsl-tray/releases)
- Extract in `%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup`

#### Set up [HHKB](https://happyhackingkb.com/) for macOS-compatible workflow

Note: this assumes Autohotkey Sharpkeys and PureText are already installed.

- Install `autohotkey.ahk` by running this from a Powershell prompt:

```powershell
cp \\wsl.localhost\Ubuntu\home\fredrik\code\dotfiles\_windows\autohotkey.ahk "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\autohotkey.ahk"
```

<details>
  <summary>Click here to see symlinking instructions</summary>

:warning: If WSL is not running, the AutoHotkey script won't run. Therefore, I
default to copying the file into place.

Symlinking can be done, instead of copying the `autohotkey.ahk`, from an
administrative Powershell prompt:

```powershell
New-Item -ItemType SymbolicLink -Path "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\autohotkey.ahk" -Value _windows\autohotkey.ahk
```

</details>

- To override <kbd>Win (Left)</kbd> + <kbd>l</kbd>, launch Sharpkeys, load the
  `\\wsl.localhost\Ubuntu\home\fredrik\code\dotfiles\_windows\sharpkeys.skl`
  file and write changes to the Registry.
- In PureText, remap (<kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>v</kbd>) to
  enable pasting of text without formatting.

### Ubuntu configuration

All commands expected to be executed in wezterm/Ubuntu.

#### Update Ubuntu

```bash
sudo apt update
sudo add-apt-repository universe
sudo apt upgrade
```

#### Shell

```bash
# NOTE: do not install shell from brew, let's keep this close to native
sudo apt install zsh

# set zsh to the default shell; /bin/zsh
chsh
```

#### Homebrew

```bash
# install homebrew
sudo apt-get install build-essential procps curl file git
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Note: Brewfile is now empty - manually add desired packages from the Nix configuration:
# - CLI tools: nix/shared/home-manager-base.nix
# - GUI apps: nix/shared/homebrew.nix (casks and brews sections)
# - Host-specific: nix/hosts/*/darwin-configuration.nix

# install all dependencies
/home/linuxbrew/.linuxbrew/bin/brew bundle --file extras/templates/Brewfile
```

You can now restart wezterm and you should be taken into Ubuntu/zsh with prompt
and most software all set up.

#### Editors

```bash
# remove folder if it already exists
rm -rf ~/.config/LazyVim


cd ~/.dotfiles
extras/installers/neovim_distros.sh

# re-run dotfiles installer, to symlink LazyVim config
../rebuild.sh --stow
```

```bash
# if you previously installed vscode
code .  # will automatically install vscode server
```

#### Additional tools

#### Tmux setup

```bash
# Install tmux plugin manager
mkdir -p ~/.tmux/plugins
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Install ruby and tmuxinator
brew install ruby
sudo gem install tmuxinator

# Install zsh completion for tmuxinator
sudo wget https://raw.githubusercontent.com/tmuxinator/tmuxinator/master/completion/tmuxinator.zsh -O /usr/local/share/zsh/site-functions/_tmuxinator
```

> [!NOTE] Don't forget to start tmux and run `<prefix> + I` to install plugins.
