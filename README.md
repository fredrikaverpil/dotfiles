# dotfiles

My personal machine setup.


### macOS setup

* Xcode
* Homebrew
* [Mac App Store command line interface](https://github.com/mas-cli/mas)
* `terminal-ocean-dark.terminal` by [Mark Otto](https://github.com/mdo/ocean-terminal)

#### Installation steps

```bash
# Avoid writing .DS_Store
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

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
```



### Symlink dotfiles

| File | Description |
| --- | --- |
| `.bash_profile` | Is executed for login shells. Exception Terminal.app: for each new terminal window, `.bash_profile` is called instead of `.bashrc`. |
| `.bashrc` | Is executed for interactive non-login shells. |
| `.gitconfig` | Global Git configuration to specify name, email,colors etc. |

```bash
ln -sf $(pwd)/bash_profile.sh ~/.bash_profile
ln -sf $(pwd)/bashrc.sh ~/.bashrc
ln -sf $(pwd)/bash_prompt.sh ~/.bash_prompt
ln -sf $(pwd)/gitconfig ~/.gitconfig
```
