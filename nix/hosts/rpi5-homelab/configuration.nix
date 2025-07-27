{ config, pkgs, lib, ... }:

let
  # Versions specific to this host
  stateVersions = {
    nixos = "25.05";
  };
in
{
  # Main configuration file for rpi5-homelab Raspberry Pi 5 system
  # This file contains all host-specific configuration consolidated from modules
  
  # ========================================================================
  # HOST CONFIGURATION
  # ========================================================================
  # Set system hostname for network identification
  networking.hostName = "rpi5-homelab";
  
  # Multi-user configuration
  dotfiles.users = {
    fredrik = {
      isAdmin = true;
      isPrimary = true;  # Not used on Linux, but kept for consistency
      shell = "zsh";
      homeConfig = ./users/fredrik.nix;
      groups = [ "networkmanager" "docker" ];
      # SSH keys can be added here:
      # sshKeys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5... your-key-here" ];
    };
  };

  # Wireless network configuration
  # Disable legacy wpa_supplicant in favor of modern iwd
  networking.wireless.enable = false;  # Disable wpa_supplicant
  networking.wireless.iwd.enable = true;  # Enable Intel's iwd for better WiFi management

  # Firewall configuration for homelab services
  # Allow specific ports for web-based management interfaces
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      9090  # Cockpit - System monitoring and administration
      8000  # Portainer - TCP tunnel server for Edge agents
      9000  # Portainer - HTTP port (legacy/optional)
      9443  # Portainer - HTTPS port (primary)
      3001  # Uptime Kuma - Service monitoring dashboard
      2283  # Immich - Photo management web interface
    ];
  };



  # Host-specific services configuration
  dotfiles.extraServices = {
    # SSH service for remote access
    # Essential for headless Raspberry Pi operation
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";  # Security: disable root login via SSH
      };
    };

    # Network Time Protocol (NTP) synchronization
    # Ensures accurate system time for logging, certificates, and scheduled tasks
    # Critical for security and proper system operation
    timesyncd = {
      enable = true;
      # Uses systemd-timesyncd for lightweight NTP client functionality
    };

    # Avahi service for mDNS/Bonjour network discovery
    # Allows the Pi to be accessible via rpi5-homelab.local on the local network
    # Essential for headless operation and easy SSH access
    avahi = {
      enable = true;
      nssmdns4 = true;  # Enable mDNS resolution in NSS for IPv4
      publish = {
        enable = true;
        addresses = true;     # Publish IP addresses via mDNS
        workstation = true;   # Announce as a workstation for better discovery
      };
    };

    # Cockpit web-based system administration interface
    # Provides system monitoring, service management, and container oversight
    # Accessible at http://rpi5-homelab.local:9090
    cockpit = {
      enable = true;
      port = 9090;
      settings = {
        WebService = {
          AllowUnencrypted = true;  # Allow HTTP for local network access
          Origins = lib.mkForce "http://rpi5-homelab.local:9090 http://localhost:9090";
        };
      };
    };
  };

  # Docker containerization platform
  # Enables running containerized applications and services
  virtualisation.docker = {
    enable = true;
  };

  # ========================================================================
  # HOMELAB DOCKER SERVICES
  # ========================================================================
  # Copy docker-compose files to system locations
  environment.etc = {
    "homelab/portainer/docker-compose.yml".source = ./docker-compose/portainer.yml;
    "homelab/uptime-kuma/docker-compose.yml".source = ./docker-compose/uptime-kuma.yml;
    "homelab/immich/docker-compose.yml".source = ./docker-compose/immich.yml;
    "homelab/immich/.env".source = ./docker-compose/immich.env;
  };

  # Systemd services for docker-compose stacks
  systemd.services = {
    homelab-portainer = {
      description = "Homelab Portainer Container Management Stack";
      after = [ "docker.service" ];
      requires = [ "docker.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        WorkingDirectory = "/etc/homelab/portainer";
        ExecStart = "${pkgs.docker-compose}/bin/docker-compose up -d";
        ExecStop = "${pkgs.docker-compose}/bin/docker-compose down";
        ExecReload = "${pkgs.docker-compose}/bin/docker-compose up -d --force-recreate";
        TimeoutStartSec = "300";
      };
      wantedBy = [ "multi-user.target" ];
    };

    homelab-uptime-kuma = {
      description = "Homelab Uptime Kuma Service Monitoring Stack";
      after = [ "docker.service" ];
      requires = [ "docker.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        WorkingDirectory = "/etc/homelab/uptime-kuma";
        ExecStart = "${pkgs.docker-compose}/bin/docker-compose up -d";
        ExecStop = "${pkgs.docker-compose}/bin/docker-compose down";
        ExecReload = "${pkgs.docker-compose}/bin/docker-compose up -d --force-recreate";
        TimeoutStartSec = "300";
      };
      wantedBy = [ "multi-user.target" ];
    };

    homelab-immich = {
      description = "Homelab Immich Photo Management Stack";
      after = [ "docker.service" ];
      requires = [ "docker.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        WorkingDirectory = "/etc/homelab/immich";
        ExecStartPre = [
          "${pkgs.coreutils}/bin/mkdir -p /var/lib/immich/library"
          "${pkgs.coreutils}/bin/mkdir -p /var/lib/immich/postgres"
        ];
        ExecStart = "${pkgs.docker-compose}/bin/docker-compose up -d";
        ExecStop = "${pkgs.docker-compose}/bin/docker-compose down";
        ExecReload = "${pkgs.docker-compose}/bin/docker-compose up -d --force-recreate";
        TimeoutStartSec = "600";  # Immich takes longer to start (ML models, etc.)
      };
      wantedBy = [ "multi-user.target" ];
    };
  };

  # ========================================================================
  # USER CONFIGURATION
  # ========================================================================
  # Note: User configuration is now handled by shared/users/default.nix

  # ========================================================================
  # HOST-SPECIFIC EXTENSIONS
  # ========================================================================
  # Host-specific system packages for rpi5-homelab
  dotfiles.extraSystemPackages = with pkgs; [
    # Essential system administration tools
    # These are kept minimal as most tools are managed via home-manager
    
    # System recovery and maintenance tools
    curl            # Network tool for downloading/API calls
    wget            # File download utility
    
    # Container tools for homelab services
    docker          # Container runtime
    docker-compose  # Container orchestration
    
    # Hardware-specific utilities for Raspberry Pi
    # These may be provided by nixos-raspberrypi modules
    
  ] ++ (with pkgs.rpi or { }; [
    # Raspberry Pi optimized packages when available
    # The nixos-raspberrypi flake may provide Pi-specific optimizations
    # These packages are conditionally included if available
    
    # Examples of Pi-specific tools that might be available:
    # - GPIO control utilities
    # - Hardware monitoring tools
    # - Pi-specific system utilities
  ]);

  # ========================================================================
  # SYSTEM METADATA
  # ========================================================================
  # System identification tags for the Raspberry Pi
  # These tags help identify the system variant and configuration
  # Following the nixos-raspberrypi project conventions
  system.nixos.tags =
    let
      cfg = config.boot.loader.raspberryPi;
    in
    [
      "raspberry-pi-${cfg.variant}"  # e.g., "raspberry-pi-5"
      cfg.bootloader                 # Bootloader type
      config.boot.kernelPackages.kernel.version  # Kernel version
    ];

  # Set system platform
  nixpkgs.hostPlatform = "aarch64-linux";

  # NixOS state version
  system.stateVersion = stateVersions.nixos;

  # System timezone configuration
  time.timeZone = "Europe/Stockholm";

  # TODO: Additional services that might be useful for a homelab:
  # - services.fail2ban.enable = true;  # Intrusion prevention
  # - services.logrotate.enable = true; # Log management (enabled by default)
  # - services.cron.enable = true;      # Scheduled tasks (enabled by default)
  
  # TODO: Security considerations:
  # - Consider enabling passwordless sudo only for specific commands
  # - Use SSH keys instead of passwords for remote access
}
