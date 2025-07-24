{ config, pkgs, ... }:

{
  # Basic darwin system settings
  nix.settings.experimental-features = "nix-command flakes";
  
  # Primary user for user-specific settings (homebrew, system defaults, etc.)
  system.primaryUser = "fredrik";

  # Enable zsh system-wide
  programs.zsh.enable = true;

  # Define the user
  users.users.fredrik = {
    name = "fredrik";
    home = "/Users/fredrik";
    shell = pkgs.zsh;  # Set zsh as default shell
  };

  # System-level packages (very few)
  environment.systemPackages = with pkgs; [
    vim # for recovery
  ];

  # Auto upgrade configuration
  # WARNING: nix-darwin doesn't support system.autoUpgrade
  # Consider manual updates instead: darwin-rebuild switch --flake ~/.dotfiles

  # macOS system defaults configuration
  # These settings modify system behavior and preferences
  system.defaults = {
    # Keyboard behavior optimizations
    # Disable press-and-hold for accent characters, enable key repeat instead
    NSGlobalDomain.ApplePressAndHoldEnabled = false;

    # File system behavior
    # Prevent .DS_Store files on network and USB drives
    CustomUserPreferences = {
      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };
    };

    # Mission Control and Spaces behavior
    # Disable automatic rearrangement of spaces based on most recent use
    dock."mru-spaces" = false;

    # Accessibility settings
    # Disable animation when switching screens or opening apps
    universalaccess.reduceMotion = true;

    # Hot corners configuration
    # Assigns actions to screen corners when cursor is moved there
    # Values correspond to specific macOS actions:
    # 0: No-op (disabled)
    # 2: Mission Control - shows all open windows and spaces
    # 3: Application Windows - shows all windows of current app
    # 4: Desktop - shows desktop by hiding all windows
    # 5: Start Screen Saver
    # 6: Disable Screen Saver
    # 7: Dashboard (deprecated in newer macOS versions)
    # 10: Put Display to Sleep
    # 11: Launchpad - shows app launcher grid
    # 12: Notification Center
    # 13: Lock Screen - immediately locks the screen
    # 14: Quick Note - opens Notes app for quick note-taking
    dock."wvous-tl-corner" = 2;  # Top-left: Mission Control (overview of all spaces)
    dock."wvous-tr-corner" = 4;  # Top-right: Desktop (show desktop)
    dock."wvous-bl-corner" = 13; # Bottom-left: Lock Screen (security)
    dock."wvous-br-corner" = 14; # Bottom-right: Quick Note (productivity)
  };

  # System activation script to apply additional macOS settings
  # These settings cannot be configured via nix-darwin and require manual defaults commands
  # Note: For non-nix systems, use _macos/set_defaults.sh instead which includes all settings
  system.activationScripts.extraActivation.text = ''
    echo "Applying additional macOS settings (nix supplement)..."
    
    # Run as the primary user to apply user-specific defaults
    sudo -u ${config.system.primaryUser} bash -c '
      # Disable Spotlight keyboard shortcut (Cmd+Space) to allow Raycast usage
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
    '
  '';
}
