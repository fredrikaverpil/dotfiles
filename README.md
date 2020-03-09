# dotfiles

## macOS with Terminal.app

![macos_bash](https://user-images.githubusercontent.com/994357/58366885-d0a4ae80-7ed8-11e9-8ed1-d3da1e75382d.png)

Set Terminal.app to use `terminal-ocean-dark.terminal`.

### Installation (bash)

```bash
# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Install Xcode commandline tools
xcode-select --install
sudo xcodebuild -license accept

# Install Homebrew
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

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
ln -sf $(pwd)/zshrc.sh ~/.zshrc
ln -sf $(pwd)/zprofile.sh ~/.zprofile
ln -sf $(pwd)/gitconfig ~/.gitconfig
ln -sf $(pwd)/gitignore_global ~/.gitignore_global
ln -sf $(pwd)/DefaultKeyBinding.dict ~/Library/KeyBindings/DefaultKeyBinding.dict

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

<br><br>

## Windows 10 with bash

![powershell](https://user-images.githubusercontent.com/994357/58366951-64767a80-7ed9-11e9-8b4e-fa9d500bef3d.png)

:stars: Linux files can be modified with Windows apps starting with Windows 10 version 1903.

### Installation (administrative Powershell)

```powershell
# Set exectution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Install Boxstarter
. { iwr -useb http://boxstarter.org/bootstrapper.ps1 } | iex; get-boxstarter -Force

# Boxstarter config
Install-BoxstarterPackage -PackageName boxstarter.ps1 -DisableReboots

# Get dotfiles
mkdir -p  ~/code/repos
cd ~/code/repos
git clone https://github.com/fredrikaverpil/dotfiles.git 
cd dotfiles

# Create symlinks
mkdir $HOME\Documents\WindowsPowerShell\
mkdir $HOME\Documents\Powershell
New-Item -ItemType SymbolicLink -Path $HOME\Documents\WindowsPowerShell\Profile.ps1 -Value Profile.ps1
New-Item -ItemType SymbolicLink -Path $HOME\Documents\Powershell\Profile.ps1 -Value Profile.ps1
New-Item -ItemType SymbolicLink -Path $HOME\.hyper.js -Value hyper.js
New-Item -ItemType SymbolicLink -Path $HOME\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\RoamingState\profiles.json -Value profiles.json
New-Item -ItemType SymbolicLink -Path $HOME\.gitconfig -Value gitconfig
```

### Installation (Ubuntu bash)

```bash
cd /mnt/c/.../code/repos/dotfiles

# Basics
sudo apt-get update
sudo apt-get install -y tmux mosh htop tree

# Docker
# Note - in Docker for Windows, first enable "Expose daemon on tcp://localhost:2375 without TLS"
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker-ce
export DOCKER_HOST=tcp://0.0.0.0:2375
# echo "export DOCKER_HOST=tcp://0.0.0.0:2375" >> ~/.bashrc

# Docker compose via Python 2
sudo apt-get install -y python python-dev python-setuptools
sudo apt-get install -y python-pip
sudo pip install docker-compose

# Miniconda
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh
chmod +x ~/miniconda.sh
bash ~/miniconda.sh -b -p $HOME/miniconda3
rm ~/miniconda.sh
sudo ln -s $HOME/miniconda3/bin/conda /usr/bin/conda

# Qt/PySide2 stuff
sudo apt-get install -y libgl1-mesa-glx xcb libxcb*
sudo apt-get install x11-apps
udo apt-get install gnome-calculator # (to get GTK)
export DISPLAY=:0
# ENV DISPLAY :99

# --- envs, to be placed in separate .bashrc symlink...
export DOCKER_HOST=tcp://0.0.0.0:2375  # Docker for Windows/bash
export DISPLAY=:0  # Tell X server to run on local computer
# export DISPLAY=localhost:0.0
# --- envs, to be placed in separate .bashrc symlink...

# Create symlinks
ln -s $(pwd)/gitconfig ~/.gitconfig
```

### Key remappings

For nicer [HHKB](https://www.hhkeyboard.com/) support and easier switching between macOS and Windows:

- [SharpKeys](http://www.randyrants.com/sharpkeys/) to remap LWin to LCtrl reliably
- [Autohotkey](https://www.autohotkey.com/) to improve home/end selection/navigation and Swedish characters on US-English keyboard/layout

<br><br>

## Symlinking details

### macOS

| File | Description |
| --- | --- |
| `.bash_profile` | Is executed for login shells. Exception Terminal.app: for each new terminal window, `.bash_profile` is called instead of `.bashrc`. |
| `.bashrc` | Is executed for interactive non-login shells. |
| `.bash_prompt` | My custom bash prompt (sourced by `.bashrc`). |
| `.gitconfig` | Global Git configuration to specify name, email, colors etc. |
| `.gitignore_global` | Global .gitignore |
| `DefaultKeyBinding.dict` | Remap US keyboard layout to support åÅäÄöÖ via <kbd>Alt</kbd> and <kbd>Alt</kbd>+<kbd>Shift</kbd> modifier keys. Note: set up macOS to switch languages via <kbd>Ctrl</kbd>+<kbd>Space</kbd>. |

### Windows

| Filepath | Description |
| --- | --- |
| `$Home\[My ]Documents\WindowsPowerShell\Profile.ps1` | Powershell 5: Current User, All Hosts|
| `$Home\[My ]Documents\Powershell\Profile.ps1` | Powershell Core: Current User, All Hosts |
| `??? profiles.ps1` | Windows Terminal profiles |

<br><br>

## Visual Code setup

Launch vscode and enter into console (<kbd>Cmd</kbd>+<kbd>Shift</kbd>+<kbd>p</kbd>):

    ext install code-settings-sync

Then provide private Github token and gist ID to sync all settings and extensions.

<br><br>

## Clone all my public repos

Note: On Windows, use Git Bash or other terminal. If more than 100 repos, change `PAGE` variable..

```bash
cd ~/code/repos
USER=fredrikaverpil; PAGE=1; curl "https://api.github.com/users/$USER/repos?page=$PAGE&per_page=100" | grep -e 'git_url*' | cut -d \" -f 4 | xargs -L1 git clone --recursive
```
