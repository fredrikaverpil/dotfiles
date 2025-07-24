#!/bin/sh -ex

# macOS settings that cannot be configured via nix-darwin
# This script is called by nix-darwin activation to supplement nix-managed settings
# For non-nix systems, use set_defaults.sh instead which includes all settings

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