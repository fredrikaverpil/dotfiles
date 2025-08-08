{
  config,
  pkgs,
  lib,
  ...
}:
# This file contains home-manager settings specific to macOS.
{
  imports = [
    ./common.nix
  ];

  home.packages = with pkgs; [
    pngpaste # for obsidian, macOS-only
  ];

  programs = {
  };

  # macOS user-specific defaults using home-manager's built-in support
  targets.darwin.defaults = {
    # Note: Keyboard and input settings moved to user-specific activation script
    # to ensure they don't affect other users on the system

    # Application-specific preferences
    "com.apple.desktopservices" = {
      # Prevent .DS_Store files on network and USB drives
      DSDontWriteNetworkStores = true;
      DSDontWriteUSBStores = true;
    };

    "com.apple.finder" = {
      ShowExternalHardDrivesOnDesktop = true;
      ShowHardDrivesOnDesktop = false;
      ShowMountedServersOnDesktop = false;
      ShowRemovableMediaOnDesktop = true;
      _FXSortFoldersFirst = true;
      # When performing a search, search the current folder by default
      FXDefaultSearchScope = "SCcf";
      DisableAllAnimations = true;
      NewWindowTarget = "PfDe";
      NewWindowTargetPath = "file://${config.home.homeDirectory}/Desktop/";
      AppleShowAllExtensions = true;
      FXEnableExtensionChangeWarning = false;
      ShowStatusBar = true;
      ShowPathbar = true;
      WarnOnEmptyTrash = false;
    };

    "com.apple.dock" = {
      autohide = true;
      launchanim = false;
      static-only = false;
      show-recents = false;
      show-process-indicators = true;
      orientation = "bottom";
      tilesize = 36;
      minimize-to-application = true;
      mineffect = "scale";
      enable-window-tool = false;
      magnification = false;
      # Mission Control and Spaces behavior
      # Disable automatic rearrangement of spaces based on most recent use
      "mru-spaces" = false;
      # Hot corners configuration
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
      "wvous-tl-corner" = 2; # Top-left: Mission Control (overview of all spaces)
      "wvous-tr-corner" = 4; # Top-right: Desktop (show desktop)
      "wvous-bl-corner" = 13; # Bottom-left: Lock Screen (security)
      "wvous-br-corner" = 14; # Bottom-right: Quick Note (productivity)
    };

    "com.apple.ActivityMonitor" = {
      OpenMainWindow = true;
      IconType = 5;
      SortColumn = "CPUUsage";
      SortDirection = 0;
    };

    "com.apple.Safari" = {
      # Privacy: don't send search queries to Apple
      UniversalSearchEnabled = false;
      SuppressSearchSuggestions = true;
    };

    "com.apple.AdLib" = {
      allowApplePersonalizedAdvertising = false;
    };

    "com.apple.TimeMachine" = {
      DoNotOfferNewDisksForBackup = true;
    };

    # Prevent Photos from opening automatically when devices are plugged in
    "com.apple.ImageCapture" = {
      disableHotPlug = true;
    };

    # Turn on app auto-update
    "com.apple.commerce" = {
      AutoUpdate = true;
    };

    # Accessibility settings
    # Disable animation when switching screens or opening apps
    "com.apple.universalaccess" = {
      reduceMotion = true;
    };
  };

  # User-specific keyboard and input settings
  # These settings only affect the current user, not other users on the system
  home.activation.userKeyboardSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    echo "Applying user-specific keyboard and input settings..."

    # Keyboard repeat settings (user-specific)
    $DRY_RUN_CMD /usr/bin/defaults write -globalDomain ApplePressAndHoldEnabled -bool false
    $DRY_RUN_CMD /usr/bin/defaults write -globalDomain InitialKeyRepeat -int 15
    $DRY_RUN_CMD /usr/bin/defaults write -globalDomain KeyRepeat -int 1

    # Mouse/trackpad settings (user-specific)
    $DRY_RUN_CMD /usr/bin/defaults write -globalDomain com.apple.mouse.tapBehavior -int 1
    $DRY_RUN_CMD /usr/bin/defaults write -globalDomain NSWindowShouldDragOnGesture -bool true

    # Spelling correction (user-specific)
    $DRY_RUN_CMD /usr/bin/defaults write -globalDomain NSAutomaticSpellingCorrectionEnabled -bool false
  '';

  # Settings that require manual defaults commands (not supported by home-manager's targets.darwin.defaults)
  home.activation.macosUserDefaults = lib.hm.dag.entryAfter ["writeBoundary"] ''
    echo "Applying additional macOS user settings..."

    # Disable input source switching (Ctrl+Space) to prevent conflicts with development tools
    $DRY_RUN_CMD /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 "
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
  '';
}
