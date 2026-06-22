# This file contains system-level settings specific to macOS, including Homebrew.
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  options = {
    host.extraBrews = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional homebrew packages for this host";
    };

    host.extraTaps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional homebrew taps for this host";
    };

    host.extraCasks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional homebrew casks for this host";
    };

    host.extraMasApps = lib.mkOption {
      type = lib.types.attrsOf lib.types.int;
      default = { };
      description = "Additional Mac App Store apps for this host";
    };

    host.extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
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
        # "joshmedeski/sesh"
        "1password/tap"
        "nikitabobko/tap"
        # "sst/tap" # for opencode
      ]
      ++ config.host.extraTaps;

      brews = [
        # Packages not available in nixpkgs
        "cloud-sql-proxy"
        "container"

        # Homebrew-managed CLIs
        # "joshmedeski/sesh/sesh"
        # "sst/tap/opencode"
        "socktainer"
        "pkgx"

        # Mac App Store CLI
        "mas"
      ]
      ++ config.host.extraBrews;

      casks = [
        "1password"
        "1password-cli"
        "aerospace"
        "appcleaner"
        "brainfm"
        "exifrenamer"
        "fujifilm-x-raw-studio"
        "gcloud-cli"
        "ghostty"
        "gitify"
        "kitty"
        "obs"
        "obsidian"
        "raycast"
        "signal"
        "slack"
        "spotify"
        "visual-studio-code"
        "wacom-tablet"
        "wezterm"
        "zed"
        "zen"
      ]
      ++ config.host.extraCasks;

      masApps = {
        # NOTE: apps run in sandboxed mode and DefaultKeyBinding.dict won't work here.
        "Keka" = 470158793;
        "Pandan" = 1569600264;
      }
      // config.host.extraMasApps;
    };

    # NOTE: Run socktainer with `socktainer --no-check-compatibility` manually during
    # the experimentation phase.
    #
    # # Socktainer runs as a user LaunchAgent so the Docker CLI and SDKs can reach
    # # Apple `container` via DOCKER_HOST=unix://$HOME/.socktainer/container.sock.
    # # `--no-check-compatibility` is required because socktainer 0.11.0 hardcodes
    # # a check for Apple container 0.11.0 but works fine against 0.12.x in practice.
    # launchd.user.agents.socktainer = {
    #   serviceConfig = {
    #     Label = "com.fredrik.socktainer";
    #     ProgramArguments = [
    #       "/opt/homebrew/opt/socktainer/bin/socktainer"
    #       "--no-check-compatibility"
    #     ];
    #     RunAtLoad = true;
    #     KeepAlive = true;
    #     StandardOutPath = "/tmp/socktainer.log";
    #     StandardErrorPath = "/tmp/socktainer.err";
    #     EnvironmentVariables = {
    #       PATH = "/opt/homebrew/bin:/usr/bin:/bin";
    #     };
    #   };
    # };

    nix.settings.experimental-features = "nix-command flakes";

    # Home-manager configuration
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = false; # Install to user profile for Darwin
      backupFileExtension = "backup";
    };

    # Primary user for user-specific settings (homebrew, system defaults, etc.)
    # Find the user marked as isPrimary = true
    system.primaryUser =
      let
        primaryUsers = lib.filterAttrs (name: user: user.isPrimary) config.host.users;
        primaryUserNames = lib.attrNames primaryUsers;
      in
      if lib.length primaryUserNames == 1 then
        lib.head primaryUserNames
      else
        throw "Exactly one user must have isPrimary = true on Darwin systems";

    # Note: User configuration is handled by lib/users.nix

    # System-level packages
    environment.systemPackages =
      with pkgs;
      [
        vim # for recovery
      ]
      ++ config.host.extraPackages;

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
      noto-fonts-color-emoji
      nerd-fonts.symbols-only
    ];
  };
}
