# dotfiles

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

