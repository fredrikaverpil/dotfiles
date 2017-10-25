# dotfiles

![terminal](https://cloud.githubusercontent.com/assets/994357/22407167/92b74982-e661-11e6-9b9d-4887286e245c.png)


### Installation steps

Requires/uses:
* Bash
* Xcode
* Homebrew
* [Mac App Store command line interface](https://github.com/mas-cli/mas)
* Terminal.app: `terminal-ocean-dark.terminal` by [Mark Otto](https://github.com/mdo/ocean-terminal)
* iTerm2:  `material-design-colors.itermcolors` by [Martin Seeler](https://github.com/MartinSeeler/iterm2-material-design)


#### macOS

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

# Install from Brewfile
brew bundle

# Check for issues
brew doctor

# Clean up
brew cleanup --force

# Install miniconda3
cd ~/Downloads && \
curl -O https://repo.continuum.io/miniconda/Miniconda3-latest-MacOSX-x86_64.sh && \
chmod +x Miniconda3-latest-MacOSX-x86_64.sh && \
./Miniconda3-latest-MacOSX-x86_64.sh

# vscode & vim condaenv
conda config --add channels conda-forge
conda create -n pythondev_35 python=3.5 pylint pep8 yapf autopep8

# Install vim-plug and install all vim plugins
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
vim +PlugInstall +qall
```

#### Windows

From administrative Powershell:

```powershell
# Set exectution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Install Boxstarter
. { iwr -useb http://boxstarter.org/bootstrapper.ps1 } | iex; get-boxstarter -Force

# Set up everything (uses boxstarter.ps1)
Install-BoxstarterPackage -PackageName boxstarter.ps1 -DisableReboots
```


### Symlink dotfiles

#### macOS

| File | Description |
| --- | --- |
| `.bash_profile` | Is executed for login shells. Exception Terminal.app: for each new terminal window, `.bash_profile` is called instead of `.bashrc`. |
| `.bashrc` | Is executed for interactive non-login shells. |
| `.bash_prompt` | My custom bash prompt (sourced by `.bashrc`). |
| `.gitconfig` | Global Git configuration to specify name, email,colors etc. |
| `.vimrc` | Vim configuration. |

```bash
ln -sf $(pwd)/bash_profile.sh ~/.bash_profile
ln -sf $(pwd)/bashrc.sh ~/.bashrc
ln -sf $(pwd)/bash_prompt.sh ~/.bash_prompt
ln -sf $(pwd)/gitconfig ~/.gitconfig
ln -sf $(pwd)/vimrc ~/.vimrc
```

#### Windows

| Filepath | Description |
| --- | --- |
| `$Home\[My ]Documents\WindowsPowerShell\Profile.ps1` | Current User, Current Host – console |
| `$Home\[My ]Documents\Profile.ps1` | Current User, All Hosts |
| `$PsHome\Microsoft.PowerShell_profile.ps1` | All Users, Current Host – console |
| `$PsHome\Profile.ps1` | All Users, All Hosts |
| `$Home\[My ]Documents\WindowsPowerShell\Microsoft.PowerShellISE_profile.ps1` | Current user, Current Host – ISE |
| `$PsHome\Microsoft.PowerShellISE_profile.ps1` | All users, Current Host – ISE |


```powershell
New-Item -ItemType HardLink -Path $HOME\Documents\WindowsPowerShell\Profile.ps1 -Value Profile.ps1
```


### Visual Code setup

Launch vscode and enter into console (cmd+shift+p):

    ext install code-settings-sync

Then provide Github token and gist ID to sync all settings and extensions.


### Clone all my public repos

Note: On Windows, use Git Bash or other terminal. If more than 100 repos, change `PAGE` variable..

```bash
cd ~/code/repos
USER=fredrikaverpil; PAGE=1; curl "https://api.github.com/users/$USER/repos?page=$PAGE&per_page=100" | grep -e 'git_url*' | cut -d \" -f 4 | xargs -L1 git clone --recursive
```
