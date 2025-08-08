# This file contains system-level settings specific to macOS, including Homebrew.
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  options = {
    host.extraBrews = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional homebrew packages for this host";
    };

    host.extraCasks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional homebrew casks for this host";
    };

    host.extraMasApps = lib.mkOption {
      type = lib.types.attrsOf lib.types.int;
      default = {};
      description = "Additional Mac App Store apps for this host";
    };

    host.extraPackages = lib.mkOption {
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
        # "joshmedeski/sesh"
        "1password/tap"
        "nikitabobko/tap"
        "sst/tap" # for opencode
      ];

      brews =
        [
          # Packages not available in nixpkgs
          "cloud-sql-proxy"
          "git-standup"

          # Presentation tools
          "slides"
          "chafa" # Required for showing images in slides

          # Packages from custom taps that aren't in nixpkgs
          "go-task/tap/go-task"
          # "joshmedeski/sesh/sesh"
          "sst/tap/opencode"
          "pkgx"

          # Mac App Store CLI
          "mas"
        ]
        ++ config.host.extraBrews;

      casks =
        [
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
        ]
        ++ config.host.extraCasks;

      masApps =
        {
          "Keka" = 470158793;
          "Slack" = 803453959;
          "Pandan" = 1569600264;
          "DoubleMemory" = 6737529034;
        }
        // config.host.extraMasApps;
    };

    nix.settings.experimental-features = "nix-command flakes";

    # Home-manager configuration
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = false; # Install to user profile for Darwin
      backupFileExtension = "backup";
    };

    # Primary user for user-specific settings (homebrew, system defaults, etc.)
    # Find the user marked as isPrimary = true
    system.primaryUser = let
      primaryUsers = lib.filterAttrs (name: user: user.isPrimary) config.host.users;
      primaryUserNames = lib.attrNames primaryUsers;
    in
      if lib.length primaryUserNames == 1
      then lib.head primaryUserNames
      else throw "Exactly one user must have isPrimary = true on Darwin systems";

    # Note: User configuration is handled by lib/users.nix

    # System-level packages
    environment.systemPackages = with pkgs; [
      vim # for recovery
    ];

    # Auto upgrade configuration
    # WARNING: nix-darwin doesn't support system.autoUpgrade
    # Consider manual updates instead: darwin-rebuild switch --flake ~/.dotfiles

    # macOS system defaults configuration
    system.defaults = {
      # System-wide settings that should apply to all users
      CustomUserPreferences = {
        "com.apple.SoftwareUpdate" = {
          AutomaticCheckEnabled = true;
          # Check for software updates daily, not just once per week
          ScheduleFrequency = 1;
          # Download newly available updates in background
          AutomaticDownload = 1;
          # Install System data files & security updates
          CriticalUpdateInstall = 1;
        };
      };
    };

    # Font management
    # NOTE: Berkeley Mono is installed manually, as it requires a license.
    fonts.packages = with pkgs; [
      nerd-fonts.fira-code
      nerd-fonts.fira-mono
      nerd-fonts.hack
      nerd-fonts.jetbrains-mono
      maple-mono.truetype
      maple-mono.variable
      noto-fonts-emoji
      nerd-fonts.symbols-only
    ];
  };
}
