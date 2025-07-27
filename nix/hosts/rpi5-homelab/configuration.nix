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
  };

  # Docker containerization platform
  # Enables running containerized applications and services
  virtualisation.docker = {
    enable = true;
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
