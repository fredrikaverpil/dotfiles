# dotfiles

![terminal](https://cloud.githubusercontent.com/assets/994357/22407167/92b74982-e661-11e6-9b9d-4887286e245c.png)


### macOS setup

Requires/uses:
* Xcode
* Homebrew
* [Mac App Store command line interface](https://github.com/mas-cli/mas)
* Terminal.app: `terminal-ocean-dark.terminal` by [Mark Otto](https://github.com/mdo/ocean-terminal)
* iTerm2:  `material-design-colors.itermcolors` by [Martin Seeler](https://github.com/MartinSeeler/iterm2-material-design)


#### Installation steps

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

# vscode & vim condaenv
conda config --add channels conda-forge
conda create -n pythondev_35 python=3.5 pylint pep8 autopep8

# Install vim-plug and install all vim plugins
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
vim +PlugInstall +qall
```


### Symlink dotfiles

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

### Visual Code setup

Launch vscode and enter into console (cmd+shift+p):

    ext install code-settings-sync

Then provide Github token and gist ID to sync all settings and extensions.
