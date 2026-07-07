# This file contains system-level settings specific to macOS, including Homebrew.
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  trustedTaps =
    taps:
    map (name: {
      inherit name;
      trusted = true;
    }) taps;

  homebrewTaps = lib.unique (
    [
      "dustinblackman/tap"
      # "joshmedeski/sesh"
      "1password/tap"
      "nikitabobko/tap"
      # "sst/tap" # for opencode
    ]
    ++ config.host.extraTaps
  );

  trustedTapArgs = lib.concatMapStringsSep " " lib.escapeShellArg homebrewTaps;
in
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

      taps = trustedTaps homebrewTaps;

      brews = [
        # Packages not available in nixpkgs
        "cloud-sql-proxy"
        "container"

        # Homebrew-managed CLIs
        # "joshmedeski/sesh/sesh"
        # "sst/tap/opencode"
        "socktainer"
        "pkgx"
        "proton-pass-cli"

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
        "proton-pass"
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

    system.activationScripts.homebrew.text = lib.mkIf config.homebrew.enable (
      lib.mkBefore ''
        # Trust configured Homebrew taps before `brew bundle` loads formulae from them.
        if [ -f "${config.homebrew.prefix}/bin/brew" ]; then
          PATH="${config.homebrew.prefix}/bin:$PATH" sudo \
            --preserve-env=PATH \
            --user=${lib.escapeShellArg config.homebrew.user} \
            --set-home \
            env HOMEBREW_NO_AUTO_UPDATE=1 \
            brew trust --quiet --tap ${trustedTapArgs}
        fi
      ''
    );

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

    # Load Proton Pass SSH keys into the native ssh-agent at login, so git/ssh
    # auth works without manually running `pass-cli ssh-agent load` (keys
    # persist in the agent for the whole login session). SSH_AUTH_SOCK is
    # inherited from the launchd user domain.
    # ponytail: RunAtLoad only, no retry — if login races the network and
    # loading fails, add KeepAlive.SuccessfulExit = false; check /tmp logs.
    launchd.user.agents.pass-cli-ssh-agent-load = {
      serviceConfig = {
        Label = "com.fredrik.pass-cli-ssh-agent-load";
        ProgramArguments = [
          "/opt/homebrew/bin/pass-cli"
          "ssh-agent"
          "load"
          "--vault-name"
          "Personal"
        ];
        RunAtLoad = true;
        StandardOutPath = "/tmp/pass-cli-ssh-agent-load.log";
        StandardErrorPath = "/tmp/pass-cli-ssh-agent-load.err";
      };
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
