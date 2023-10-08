## Windows 11 + WSL

⚠️ These instructions are likely to become outdated, as my primary system is macOS.

This setup aims to run GUIs in Windows with all terminal and coding activities in WSL/Ubuntu.

Prop tip: set up Wezterm, dotfiles repo and homebrew first.

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

Then install GUI apps (from [Microsoft Store](https://www.microsoft.com/en-us/store/apps/windows) and [winget-pkgs repo](https://github.com/microsoft/winget-pkgs)) in Windows from a Powershell prompt:

```powershell
# Coding
winget install wez.wezterm  # or maybe just install via setup.exe installer...?
# winget install --accept-package-agreements --source msstore "Windows Terminal" --id 9N0DX20HK701
# winget install --accept-package-agreements --source msstore "Visual Studio Code" --id XP9KHM4BK9FZ7Q
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
mkdir -p code/repos && cd code/repos
git clone https://github.com/fredrikaverpil/dotfiles.git
cd dotfiles && ./install -vv
```

### Windows configuration

#### Wezterm

From administrative Powershell prompt:

```powershell
cd \\wsl.localhost\Ubuntu\home\fredrik\code\repos\dotfiles

New-Item -ItemType SymbolicLink -Path $HOME\.wezterm.lua -Value wezterm.lua
```

Restart wezterm, and it should now start up straight into Ubuntu.

<details>
  <summary>Click here for old notes on the Windows Terminal.</summary>

#### Windows Terminal

Run from administrative Powershell prompt:

```powershell
# Remove original settings.json
rm $HOME\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json

# Create symlink into WSL2's dotfiles repo
cd \\wsl.localhost\Ubuntu\home\fredrik\code\repos\dotfiles

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
cp \\wsl.localhost\Ubuntu\home\fredrik\code\repos\dotfiles\_windows\autohotkey.ahk "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\autohotkey.ahk"
```

<details>
  <summary>Click here to see symlinking instructions</summary>

Symlinking can be done, instead of copying the `autohotkey.ahk`, from an administrative Powershell prompt:

```powershell
New-Item -ItemType SymbolicLink -Path "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\autohotkey.ahk" -Value _windows\autohotkey.ahk
```

:warning: ...however, if WSL is not running, the AutoHotkey script won't run. It may be more desireable to copy the file into place.

</details>

- To override <kbd>Win (Left)</kbd> + <kbd>l</kbd>, launch Sharpkeys, load the `\\wsl.localhost\Ubuntu\home\fredrik\code\repos\dotfiles\_windows\sharpkeys.skl` file and write changes to the Registry.
- In PureText, remap (<kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>v</kbd>) to enable pasting of text without formatting.


### Ubuntu configuration

#### Update Ubuntu

```bash
sudo apt update
sudo add-apt-repository universe
sudo apt upgrade
```

#### Homebrew

```bash
installers/homebrew.sh
```

#### Shell

```bash
brew install zsh

# remove the default prompt from ~/.zshrc after installation ...?

# set zsh to the default shell
chsh
```

#### Editors

```bash
brew install neovim

installers/neovim_distros.sh
```

```bash
code .  # will automatically install vscode server
```

#### Additional tools

```bash
brew bundle --file _linux/Brewfile

installers/ ...
```

## To do

- 1Password git credentials.
