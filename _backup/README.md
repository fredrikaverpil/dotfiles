# dotfiles

## Windows 10

:stars: Linux files can be modified with Windows apps starting with Windows 10 version 1903.  
:warning: Operating on `/mnt/c` from within WSL2 is slow (it's a network mount), avoid this.

### WSL2 Ubuntu 20.04

From administrative Powershell:

```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
```

Restart, then again from administrative Powershell:

```powershell
wsl --set-default-version 2
```

Install Ubuntu 20.04 LTS and Terminal from the Microsoft Store.

Install the [Linux Kernel update package](https://docs.microsoft.com/en-us/windows/wsl/install-win10#step-4---download-the-linux-kernel-update-package).

Install [Docker Desktop with WSL2 backend](https://docs.docker.com/docker-for-windows/wsl) and add `$USER` to the `docker` group:

```bash
sudo usermod -aG docker ${USER}
```

Set up Python basics:

```bash
sudo apt update

# pyenv
sudo apt-get install --no-install-recommends make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash

# pipx
pyenv install 3.9.2
pyenv global 3.9.2
PIP_REQUIRE_VIRTUALENV=false pip install -U pip
PIP_REQUIRE_VIRTUALENV=false pip install pipx
pyenv global system

# poetry
pipx install poetry --pip-args poetry-dynamic-versioning --suffix @work
pipx install git+https://github.com/python-poetry/poetry.git --suffix @master
```

Get the dotfiles:

```bash
mkdir -p  ~/code/repos
cd ~/code/repos
git clone https://github.com/fredrikaverpil/dotfiles.git 
cd dotfiles

# Create symlinks
cat $(pwd)/bashrc.sh >> ~/.bashrc
ln -sf $(pwd)/bash_profile.sh ~/.bash_profile
ln -sf $(pwd)/bash_exports.sh ~/.bash_exports
ln -sf $(pwd)/bash_aliases.sh ~/.bash_aliases
ln -sf $(pwd)/bash_venv.sh ~/.bash_venv
ln -sf $(pwd)/gitconfig ~/.gitconfig
ln -sf $(pwd)/gitignore_global ~/.gitignore_global

# Choose one of the two prompts...
# a) Starship prompt
# Requires Starship installation first: https://starship.rs/
ln -sf $(pwd)/bash_prompt_starship.sh ~/.bash_prompt
ln -sf $(pwd)/starship.toml ~/.config/starship.toml
# b) Home made prompt
ln -sf $(pwd)/bash_prompt.sh ~/.bash_prompt
```


Set up SSH:

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
touch ~/.ssh/known_hosts && chmod 644 ~/.ssh/known_hosts
touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys
# add key(s) here
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
```

### Git bash for Windows

:warning: Outdated. Use WSL2 instead!

```powershell
# Administrative Powershell

# Set exectution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Get dotfiles
mkdir -p  ~/code/repos
cd ~/code/repos
git clone https://github.com/fredrikaverpil/dotfiles.git 
cd dotfiles

# Create symlinks
New-Item -ItemType SymbolicLink -Path $HOME\.gitconfig -Value gitconfig
New-Item -ItemType SymbolicLink -Path $HOME\.gitignore_global -Value gitignore_global
New-Item -ItemType SymbolicLink -Path $HOME\.bashrc -Value bashrc.sh
New-Item -ItemType SymbolicLink -Path $HOME\.bash_profile -Value bash_profile.sh
New-Item -ItemType SymbolicLink -Path $HOME\.bash_exports -Value bash_exports.sh
New-Item -ItemType SymbolicLink -Path $HOME\.bash_aliases -Value bash_aliases.sh
New-Item -ItemType SymbolicLink -Path $HOME\.bash_prompt -Value bash_prompt.sh

New-Item -ItemType SymbolicLink -Path "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\autohotkey.ahk" -Value autohotkey.ahk
```

### Powershell, Powershell Core and Windows Terminal profiles

![powershell](https://user-images.githubusercontent.com/994357/58366951-64767a80-7ed9-11e9-8b4e-fa9d500bef3d.png)

:warning: This is outdated, need updating. Also, see Boxstarter script for duplicate config.

```powershell
# Administrative Powershell

# Set exectution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Update PowerShellGet
Install-Module PowerShellGet -Scope CurrentUser -Force -AllowClobber

# Install posh-git
PowerShellGet\Install-Module posh-git -Scope CurrentUser -AllowPrerelease -Force


mkdir $HOME\Documents\WindowsPowerShell\
mkdir $HOME\Documents\Powershell
New-Item -ItemType SymbolicLink -Path $HOME\Documents\WindowsPowerShell\Profile.ps1 -Value Profile.ps1
New-Item -ItemType SymbolicLink -Path $HOME\Documents\Powershell\Profile.ps1 -Value Profile.ps1
New-Item -ItemType SymbolicLink -Path $HOME\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\RoamingState\profiles.json -Value profiles.json
```

### Boxstarter

:warning: Outdated.

```powershell
# Administrative Powershell

# Install Boxstarter
. { iwr -useb http://boxstarter.org/bootstrapper.ps1 } | iex; get-boxstarter -Force

# Boxstarter config
Install-BoxstarterPackage -PackageName boxstarter.ps1 -DisableReboots
```

### Key remappings

For nicer [HHKB](https://www.hhkeyboard.com/) support and easier switching between macOS and Windows:

- [SharpKeys](http://www.randyrants.com/sharpkeys/) to remap <kbd>LWin</kbd> to <kbd>LCtrl</kbd> reliably
- [Autohotkey](https://www.autohotkey.com/) to improve home/end selection/navigation and Swedish characters on US-English keyboard/layout
- [PureText](http://stevemiller.net/puretext/) to remap (<kbd>RWin</kbd> + <kbd>v</kbd>) to enable pasting of text without formatting

## macOS

### Bash/ZSH with Terminal.app

![macos_bash](https://user-images.githubusercontent.com/994357/58366885-d0a4ae80-7ed8-11e9-8ed1-d3da1e75382d.png)

Set Terminal.app to use `terminal-ocean-dark.terminal`.

```bash
# Get dotfiles
mkdir -p  ~/code/repos
cd ~/code/repos
git clone https://github.com/fredrikaverpil/dotfiles.git 
cd dotfiles

# Create symlinks
ln -sf $(pwd)/bashrc.sh ~/.bashrc
ln -sf $(pwd)/bash_profile.sh ~/.bash_profile
ln -sf $(pwd)/bash_exports.sh ~/.bash_exports
ln -sf $(pwd)/bash_aliases.sh ~/.bash_aliases
ln -sf $(pwd)/bash_prompt.sh ~/.bash_prompt
ln -sf $(pwd)/bash_venv.sh ~/.bash_venv
ln -sf $(pwd)/zshrc.sh ~/.zshrc
ln -sf $(pwd)/zprofile.sh ~/.zprofile
ln -sf $(pwd)/zprompt.sh ~/.zprompt
ln -sf $(pwd)/gitconfig ~/.gitconfig
ln -sf $(pwd)/gitignore_global ~/.gitignore_global


# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### Key remappings

```bash
ln -sf $(pwd)/DefaultKeyBinding.dict ~/Library/KeyBindings/DefaultKeyBinding.dict
```

### Extras

```bash
# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Install Xcode commandline tools
xcode-select --install
sudo xcodebuild -license accept

# Install Homebrew
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Install from Brewfile
brew bundle

# Check for issues
brew doctor

# Clean up
brew cleanup --force

# Miniconda
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh
chmod +x ~/miniconda.sh
bash ~/miniconda.sh -b -p $HOME/miniconda3
rm ~/miniconda.sh
# ln -s $HOME/miniconda3/bin/conda /usr/bin/conda  # haven't tried this on macOS yet
```

## Red Hat 7

### Bash/ZSH

```bash
# Get dotfiles
mkdir -p  ~/code/repos
cd ~/code/repos
git clone https://github.com/fredrikaverpil/dotfiles.git 
cd dotfiles

# Create symlinks
ln -sf $(pwd)/bashrc.sh ~/.bashrc
ln -sf $(pwd)/bash_profile.sh ~/.bash_profile
ln -sf $(pwd)/bash_exports.sh ~/.bash_exports
ln -sf $(pwd)/bash_aliases.sh ~/.bash_aliases
ln -sf $(pwd)/bash_modules.sh ~/.bash_modules
ln -sf $(pwd)/bash_prompt.sh ~/.bash_prompt
ln -sf $(pwd)/bash_venv.sh ~/.bash_venv
ln -sf $(pwd)/gitconfig ~/.gitconfig
ln -sf $(pwd)/gitignore_global ~/.gitignore_global
```

## Symlinking details

### Windows

| Filepath | Description |
| --- | --- |
| `$Home\[My ]Documents\WindowsPowerShell\Profile.ps1` | Powershell 5: Current User, All Hosts|
| `$Home\[My ]Documents\Powershell\Profile.ps1` | Powershell Core: Current User, All Hosts |
| `??? profiles.ps1` | Windows Terminal profiles |

### macOS

| File | Description |
| --- | --- |
| `.bash_profile` | Is executed for login shells. Exception Terminal.app: for each new terminal window, `.bash_profile` is called instead of `.bashrc`. |
| `.bashrc` | Is executed for interactive non-login shells. |
| `.bash_prompt` | My custom bash prompt (sourced by `.bashrc`). |
| `.bash_modules` | Loads modules in e.g. Red Hat. |
| `.bash_venv` | Pyenv init and auto-detection of .venv folders. |
| `.gitconfig` | Global Git configuration to specify name, email, colors etc. |
| `.gitignore_global` | Global .gitignore |
| `DefaultKeyBinding.dict` | Remap US keyboard layout to support åÅäÄöÖ via <kbd>Alt</kbd> and <kbd>Alt</kbd>+<kbd>Shift</kbd> modifier keys. Note: set up macOS to switch languages via <kbd>Ctrl</kbd>+<kbd>Space</kbd>. |

## Visual Code setup

Launch vscode and enter into console (<kbd>Cmd</kbd>+<kbd>Shift</kbd>+<kbd>p</kbd>):

    ext install code-settings-sync

Then provide private Github token and gist ID to sync all settings and extensions.

## Clone all my public repos

Note: On Windows, use Git Bash or other terminal. If more than 100 repos, change `PAGE` variable..

```bash
cd ~/code/repos
USER=fredrikaverpil; PAGE=1; curl "https://api.github.com/users/$USER/repos?page=$PAGE&per_page=100" | grep -e 'git_url*' | cut -d \" -f 4 | xargs -L1 git clone --recursive
```
