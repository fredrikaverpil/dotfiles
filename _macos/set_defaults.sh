#!/bin/sh -ex

# Based on
# https://github.com/kevinSuttle/macOS-Defaults/blob/master/.macos

# Disable press-and-hold for keys in favor of key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Set a blazingly fast keyboard repeat rate
# The defaults for a freshly installed macOS Sierra 10.12.5 (16F73) are: KeyRepeat = 6 and InitialKeyRepeat = 25.
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Disable .DS_Store files on network volumes and USB drives
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
