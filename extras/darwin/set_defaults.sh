#!/bin/sh -ex

# Based on
# https://github.com/kevinSuttle/macOS-Defaults/blob/master/.macos

# Complete macOS defaults configuration for systems without nix-darwin
# For nix-darwin systems, some of these settings are managed by nix configuration
# and only the supplement script (set_defaults_nix_supplement.sh) is needed

# Disable press-and-hold for keys in favor of key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Set a blazingly fast keyboard repeat rate
# The defaults for a freshly installed macOS Sierra 10.12.5 (16F73) are: KeyRepeat = 6 and InitialKeyRepeat = 25.
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Disable .DS_Store files on network volumes and USB drives
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Disable animation when switching screens or opening apps (reduce motion)
defaults write com.apple.universalaccess reduceMotion -bool true

# Disable Spotlight keyboard shortcut (Cmd+Space) to allow Raycast usage
# This setting cannot be configured via nix-darwin symbolic hotkeys
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 "
  <dict>
    <key>enabled</key><false/>
    <key>value</key><dict>
      <key>type</key><string>standard</string>
      <key>parameters</key>
      <array>
        <integer>32</integer>
        <integer>49</integer>
        <integer>1048576</integer>
      </array>
    </dict>
  </dict>
"

# Disable input source switching (Ctrl+Space) to prevent conflicts with development tools
# This setting cannot be configured via nix-darwin
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 "
  <dict>
    <key>enabled</key><false/>
    <key>value</key><dict>
      <key>type</key><string>standard</string>
      <key>parameters</key>
      <array>
        <integer>32</integer>
        <integer>49</integer>
        <integer>262144</integer>
      </array>
    </dict>
  </dict>
"
