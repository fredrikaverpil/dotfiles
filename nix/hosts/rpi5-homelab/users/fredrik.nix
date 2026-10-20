{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [
    ../../../shared/home/linux.nix # Import shared Linux home-manager configuration
  ];

  home.stateVersion = "25.05";

  llmAgents = [ ];

  home.packages = with pkgs; [
    unstable.neovim
  ];

  home.sessionVariables = {
    # Stowed from stow/host/rpi5-homelab, in place of the shared mise config.
    MISE_GLOBAL_CONFIG_FILE = "${config.home.homeDirectory}/.config/mise/config.rpi5-homelab.toml";
    # Stops mise loading the shared ~/.config/mise/config.toml as a project
    # config from any directory under $HOME.
    MISE_CEILING_PATHS = config.home.homeDirectory;
  };

  home.file = {
  };

  programs = {
  };

  # Claude Code remote-control server service
  # Runs automatically on boot, accessible via remote-control protocol
  # Working directory: ~/code/public
  systemd.user.services.claude-code-server = {
    Unit = {
      Description = "Claude Code Remote Control Server";
      # No network-online.target dependency: user services cannot meaningfully
      # order against that system target, and it can stall boot on WiFi ARM
      # hosts. Restart=always below reconnects once the network is up.
    };

    Service = {
      Type = "simple";
      WorkingDirectory = "%h/code/public";
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/code/public";
      ExecStart = "${pkgs.bash}/bin/bash -c 'exec $HOME/.nix-profile/bin/claude remote-control --permission-mode auto'";
      Restart = "always";
      RestartSec = "10";

      # Logging
      StandardOutput = "journal";
      StandardError = "journal";

      # Environment
      Environment = [
        "PATH=%h/.nix-profile/bin:${
          lib.makeBinPath [
            pkgs.git
            pkgs.coreutils
            pkgs.findutils
            pkgs.gnugrep
            pkgs.gnused
            pkgs.gawk
          ]
        }"
      ];
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  # OpenCode headless server service
  # Runs automatically on boot, mirroring the Claude Code remote-control server
  # above but for a provider-agnostic agent (OpenRouter etc.).
  #
  # Reachability: binds 0.0.0.0 but is *not* added to networking.firewall
  # allowedTCPPorts, so the local network is blocked while the trusted
  # "tailscale+" interface (see configuration.nix) passes. Net effect:
  # reachable over Tailscale only, at http://rpi5-homelab:4096. Because the
  # process binds 0.0.0.0, that firewall allowlist is the only LAN barrier:
  # do NOT add port 4096 to allowedTCPPorts, or Basic auth would be exposed
  # over cleartext HTTP on the local network.
  #
  # Auth: HTTP Basic auth (user "opencode") with the password from
  # OPENCODE_PASSWORD, supplied out-of-band via EnvironmentFile (mirrors the
  # restic.nix secret convention) and never tracked in git. Without one,
  # OpenCode generates a random password and prints it to the journal. The
  # unit fails closed on both a missing and an empty secret: EnvironmentFile
  # without a leading "-" fails the unit if the file is absent, and the
  # ${OPENCODE_PASSWORD:?...} guard in ExecStart refuses to start if the
  # variable is unset or empty. Create the secret atomically (single write,
  # never an empty intermediate state) once on the host:
  #   ( umask 077; printf 'OPENCODE_PASSWORD=%s\n' \
  #       "$(openssl rand -base64 24)" > ~/.config/opencode/server.env )
  # and log in to a provider once with: opencode2 auth login
  # Clients connect with: OPENCODE_PASSWORD=... opencode2 --server <url>
  #
  # Working directory: ~/code/public
  systemd.user.services.opencode-server = {
    Unit = {
      Description = "OpenCode Headless Server";
      # No network-online.target dependency: user services cannot meaningfully
      # order against that system target, and it can stall boot on WiFi ARM
      # hosts. Restart=always below reconnects once the network is up.
    };

    Service = {
      Type = "simple";
      WorkingDirectory = "%h/code/public";
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/code/public";
      # The ${OPENCODE_PASSWORD:?...} guard fails the unit closed when the
      # secret is unset or empty, so the server never comes up without the
      # known password (see the auth note above).
      ExecStart = "${pkgs.bash}/bin/bash -c ': \"\${OPENCODE_PASSWORD:?set OPENCODE_PASSWORD in server.env}\"; exec $HOME/.nix-profile/bin/opencode2 serve --hostname 0.0.0.0 --port 4096 --print-logs'";
      Restart = "always";
      RestartSec = "10";

      # HTTP Basic auth secret (OPENCODE_PASSWORD), supplied out-of-band
      # and not tracked in git. No leading "-": the file is required, so an
      # absent secret fails the unit; the ExecStart guard additionally covers
      # a present-but-empty secret.
      EnvironmentFile = "%h/.config/opencode/server.env";

      # Logging
      StandardOutput = "journal";
      StandardError = "journal";

      # Environment
      Environment = [
        "PATH=%h/.nix-profile/bin:${
          lib.makeBinPath [
            pkgs.git
            pkgs.coreutils
            pkgs.findutils
            pkgs.gnugrep
            pkgs.gnused
            pkgs.gawk
          ]
        }"
      ];
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
