## macOS

### Install dotfiles

Install:

```bash
mkdir -p code/repos && cd code/repos
git clone https://github.com/fredrikaverpil/dotfiles.git
cd dotfiles && ./install -vv
```

### Optional installation

Install Xcode commandline tools:

```bash
xcode-select --install
sudo xcodebuild -license accept
```

Install CLI and GUI apps:

```bash
installers/homebrew.sh
brew bundle --file=_macos/Brewfile
brew bundle --file=_macos/Brewfile_mas  # Requires having logged into the App Store
```

```bash
installers/*.sh
```

### Configuration

Avoid creating .DS_Store files on network or USB volumes:

```bash
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
```
