# dotfiles


## macOS


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

# Get dotfiles
mkdir -p  ~/code/repos
cd ~/code/repos
git clone https://github.com/fredrikaverpil/dotfiles.git 
cd dotfiles

# Create symlinks
ln -sf $(pwd)/bash_profile.sh ~/.bash_profile
ln -sf $(pwd)/bashrc.sh ~/.bashrc
ln -sf $(pwd)/bash_prompt.sh ~/.bash_prompt
ln -sf $(pwd)/gitconfig ~/.gitconfig
ln -sf $(pwd)/vimrc ~/.vimrc

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

# Install vim-plug and install all vim plugins
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
vim +PlugInstall +qall
```

<br><br>


## Windows 10 with bash

:warning: Never change Linux files in Windows apps or you risk data corruption.


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
New-Item -ItemType HardLink -Path $HOME\Documents\WindowsPowerShell\Profile.ps1 -Value Profile.ps1
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
ln -s $(pwd)/vimrc ~/.vimrc
ln -s $(pwd)/gitconfig ~/.gitconfig

# Install vim-plug and install all vim plugins
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
vim +PlugInstall +qall
```


<br><br>

## Symlinking details

### macOS

| File | Description |
| --- | --- |
| `.bash_profile` | Is executed for login shells. Exception Terminal.app: for each new terminal window, `.bash_profile` is called instead of `.bashrc`. |
| `.bashrc` | Is executed for interactive non-login shells. |
| `.bash_prompt` | My custom bash prompt (sourced by `.bashrc`). |
| `.gitconfig` | Global Git configuration to specify name, email,colors etc. |
| `.vimrc` | Vim configuration. |


### Windows

| Filepath | Description |
| --- | --- |
| `$Home\[My ]Documents\WindowsPowerShell\Profile.ps1` | Current User, Current Host – console |
| `$Home\[My ]Documents\Profile.ps1` | Current User, All Hosts |
| `$PsHome\Microsoft.PowerShell_profile.ps1` | All Users, Current Host – console |
| `$PsHome\Profile.ps1` | All Users, All Hosts |
| `$Home\[My ]Documents\WindowsPowerShell\Microsoft.PowerShellISE_profile.ps1` | Current user, Current Host – ISE |
| `$PsHome\Microsoft.PowerShellISE_profile.ps1` | All users, Current Host – ISE |


<br><br>


## Visual Code setup

```bash
conda config --add channels conda-forge
conda create -y -n pythondev_35 python=3.5 pylint pep8 yapf autopep8
```

Launch vscode and enter into console (cmd+shift+p):

    ext install code-settings-sync

Then provide Github token and gist ID to sync all settings and extensions.


<br><br>


## Clone all my public repos

Note: On Windows, use Git Bash or other terminal. If more than 100 repos, change `PAGE` variable..

```bash
cd ~/code/repos
USER=fredrikaverpil; PAGE=1; curl "https://api.github.com/users/$USER/repos?page=$PAGE&per_page=100" | grep -e 'git_url*' | cut -d \" -f 4 | xargs -L1 git clone --recursive
```
