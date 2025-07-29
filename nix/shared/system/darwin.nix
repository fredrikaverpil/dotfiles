# This file contains system-level settings specific to macOS, including Homebrew.

{ config, pkgs, lib, inputs, ... }:

{
  options = {
    dotfiles.extraBrews = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional homebrew packages for this host";
    };

    dotfiles.extraCasks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional homebrew casks for this host";
    };

    dotfiles.extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Additional packages for this host";
    };
  };

  config = {
    homebrew = {
      enable = true;
      onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };

    taps = [
      "dustinblackman/tap"
      "go-task/tap"
      "joshmedeski/sesh"
      "1password/tap"
      "nikitabobko/tap"
      "sst/tap" # for opencode
    ];

    brews = [
      # Packages not available in nixpkgs
      "cloud-sql-proxy"
      "git-standup"
      
      # Presentation tools
      "slides"
      "chafa" # Required for showing images in slides
      
      # Packages from custom taps that aren't in nixpkgs
      "go-task/tap/go-task"
      "joshmedeski/sesh/sesh"
      "sst/tap/opencode"
      "pkgx"
    ] ++ config.dotfiles.extraBrews;

    casks = [
      "1password"
      "1password-cli"
      "aerospace"
      "appcleaner"
      "fujifilm-x-raw-studio"
      "ghostty"
      "gitify"
      "gcloud-cli"
      "kitty"
      "obs"
      "obsidian"
      "signal"
      "spotify"
      "visual-studio-code"
      "wacom-tablet"
      "wezterm"
      "zed"
    ] ++ config.dotfiles.extraCasks;

    masApps = {
      "Keka" = 470158793;
      "Slack" = 803453959;
      "Pandan" = 1569600264;
    };
  };

  nix.settings.experimental-features = "nix-command flakes";
  
  # Primary user for user-specific settings (homebrew, system defaults, etc.)
  # Find the user marked as isPrimary = true
  system.primaryUser = 
    let 
      primaryUsers = lib.filterAttrs (name: user: user.isPrimary) config.dotfiles.users;
      primaryUserNames = lib.attrNames primaryUsers;
    in
      if lib.length primaryUserNames == 1 
      then lib.head primaryUserNames
      else throw "Exactly one user must have isPrimary = true on Darwin systems";
  
  # Note: User configuration is handled by shared/users/default.nix

  # System-level packages
  environment.systemPackages = with pkgs; [
    vim # for recovery
  ];

  # Auto upgrade configuration
  # WARNING: nix-darwin doesn't support system.autoUpgrade
  # Consider manual updates instead: darwin-rebuild switch --flake ~/.dotfiles

  # macOS system defaults configuration
  system.defaults = {
    # Keyboard behavior optimizations
    # Disable press-and-hold for accent characters, enable key repeat instead
    NSGlobalDomain.ApplePressAndHoldEnabled = false;
    NSGlobalDomain.InitialKeyRepeat = 25;
    NSGlobalDomain.KeyRepeat = 2;
    NSGlobalDomain."com.apple.mouse.tapBehavior" = 1;
    NSGlobalDomain.NSWindowShouldDragOnGesture = true;
    NSGlobalDomain.NSAutomaticSpellingCorrectionEnabled = false;

    # File system behavior
    # Prevent .DS_Store files on network and USB drives
    CustomUserPreferences = {
      "com.apple.desktopservices" = {
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
        NewWindowTargetPath = "file://$\{HOME\}/Desktop/";
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
      };
      "com.apple.ActivityMonitor" = {
        OpenMainWindow = true;
        IconType = 5;
        SortColumn = "CPUUsage";
        SortDirection = 0;
      };
      "com.apple.Safari" = {
        # Privacy: don’t send search queries to Apple
        UniversalSearchEnabled = false;
        SuppressSearchSuggestions = true;
      };
      "com.apple.AdLib" = {
        allowApplePersonalizedAdvertising = false;
      };
      "com.apple.SoftwareUpdate" = {
        AutomaticCheckEnabled = true;
        # Check for software updates daily, not just once per week
        ScheduleFrequency = 1;
        # Download newly available updates in background
        AutomaticDownload = 1;
        # Install System data files & security updates
        CriticalUpdateInstall = 1;
      };
      "com.apple.TimeMachine".DoNotOfferNewDisksForBackup = true;
      # Prevent Photos from opening automatically when devices are plugged in
      "com.apple.ImageCapture".disableHotPlug = true;
      # Turn on app auto-update
      "com.apple.commerce".AutoUpdate = true;
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
    dock."wvous-tl-corner" = 2; # Top-left: Mission Control (overview of all spaces)
    dock."wvous-tr-corner" = 4; # Top-right: Desktop (show desktop)
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

  # Nix registry for easy access to stable and unstable packages
  nix.registry = {
    n.to = {
      type = "path";
      path = inputs.nixpkgs;
    };
    u.to = {
      type = "path";
      path = inputs.nixpkgs-unstable;
    };
  };

  # Font management
  # NOTE: Berkeley Mono is installed manually, as it requires a license.
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.fira-mono
    nerd-fonts.hack
    nerd-fonts.jetbrains-mono
    maple-mono.NF
    noto-fonts-emoji
    nerd-fonts.symbols-only
  ];
  };
}
