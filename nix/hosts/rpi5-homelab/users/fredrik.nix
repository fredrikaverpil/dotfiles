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

  packageTools.npmPackages = [ ];
  packageTools.uvTools = [ ];

  home.packages = with pkgs; [ ];

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
        "PATH=%h/.nix-profile/bin:${lib.makeBinPath [ pkgs.git pkgs.coreutils pkgs.findutils pkgs.gnugrep pkgs.gnused pkgs.gawk ]}"
      ];
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
