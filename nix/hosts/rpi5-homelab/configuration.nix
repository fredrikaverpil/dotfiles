{ config, pkgs, lib, inputs, ... }:

let
  # Versions specific to this host
  stateVersions = {
    nixos = "25.05";
  };
in
{
  # Import agenix module for secrets management
  imports = [ 
    inputs.agenix.nixosModules.default
    # ./secrets/secrets.nix  # Will be enabled after key generation
  ];

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
      # SSH keys for secure access (RECOMMENDED: add your public key here)
      # This enables immediate key-based access on fresh installs
      # Generate key: ssh-keygen -t ed25519 -C "your-email@example.com"
      # Then add your ~/.ssh/id_ed25519.pub content below:
      sshKeys = [ 
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIElRYEYxPt8po0TToz1U5bNZYJgnho7xIgApCh9DTfyn"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJKGKlggcQ6VquiOwiXz5505VnlzRXz6LWW8odDx6URk"
        # Add additional keys here if needed
      ];
    };
  };

  # Wireless network configuration
  # Disable legacy wpa_supplicant in favor of modern iwd
  networking.wireless.enable = false;  # Disable wpa_supplicant
  networking.wireless.iwd.enable = true;  # Enable Intel's iwd for better WiFi management

  # Firewall configuration for homelab services
  # Maximum security: no SSH exposed to internet, only via Tailscale VPN
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      # Local network + Tailscale access only
      22    # SSH - Local network and Tailscale VPN access only
      
      # Homelab service ports (local network access)
      9090  # Cockpit - System monitoring and administration
      8000  # Portainer - TCP tunnel server for Edge agents  
      9000  # Portainer - HTTP port (legacy/optional)
      9443  # Portainer - HTTPS port (primary)
      3001  # Uptime Kuma - Service monitoring dashboard
      2283  # Immich - Photo management web interface
      8096  # Jellyfin - Media server web interface
      
      # Optional: Uncomment if you need direct internet access to web services
      # 80    # HTTP - Web services
      # 443   # HTTPS - Secure web services
    ];
    
    # Allow Tailscale traffic
    trustedInterfaces = [ "tailscale0" ];
  };



  # Host-specific services configuration
  dotfiles.extraServices = {
    # SSH service for remote access
    # Accessible via local network and Tailscale VPN only (not internet-exposed)
    openssh = {
      enable = true;
      ports = [ 22 ];  # Standard SSH port (safe since not internet-exposed)
      settings = {
        PermitRootLogin = "no";           # Security: disable root login via SSH
        # Password auth is safer now since SSH is not internet-exposed
        PasswordAuthentication = true;    # Safe for local network + Tailscale access
        KbdInteractiveAuthentication = false;  # Security: disable keyboard-interactive auth
        PubkeyAuthentication = true;      # Enable SSH key authentication (default, but explicit)
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

    # Dynamic DNS client for Cloudflare integration
    # Updates DNS records when public IP changes for internet accessibility
    # Uses agenix for secure secret management (API token and domain name)
    # Dynamic DNS client for Cloudflare integration
    # TEMPORARILY DISABLED - will be enabled after agenix secrets are created
    # Uses agenix for secure secret management (API token and domain name)
    ddclient = {
      enable = false;  # Will be enabled after secrets are set up
      protocol = "cloudflare";
      server = "cloudflare";
      username = "token";  # Cloudflare uses 'token' as username for API token auth
      # passwordFile = config.age.secrets.cloudflare-token.path;
      # domains = [ (lib.strings.removeSuffix "\n" (builtins.readFile config.age.secrets.homelab-domain.path)) ];
      verbose = true;
      ssl = true;
      interval = "300";  # Update every 5 minutes
    };

    # Tailscale mesh VPN for secure remote access
    # Provides encrypted access without exposing SSH to internet
    tailscale = {
      enable = true;
      # Allow Tailscale to manage routing and DNS
      useRoutingFeatures = "client";
    };

    # fail2ban intrusion prevention system
    # Now only needed for local network protection (SSH not internet-exposed)
    fail2ban = {
      enable = true;
      bantime = "1h";        # Ban duration: 1 hour
      maxretry = 5;          # Increased to 5 since only local network access
      ignoreIP = [
        "127.0.0.1/8"        # Never ban localhost
        "192.168.0.0/16"     # Never ban local network (adjust if needed)
        "10.0.0.0/8"         # Never ban private networks
        "172.16.0.0/12"      # Never ban private networks
        "100.64.0.0/10"      # Never ban Tailscale network
      ];
      jails = {
        # SSH jail configuration
        sshd = {
          settings = {
            enabled = true;
            port = "22";       # Standard SSH port (local + Tailscale only)
            findtime = "10m";  # Time window to look for failures: 10 minutes
          };
        };
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
    "homelab/jellyfin/docker-compose.yml".source = ./docker-compose/jellyfin.yml;
    "homelab/jellyfin/.env".source = ./docker-compose/jellyfin.env;
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

    homelab-jellyfin = {
      description = "Homelab Jellyfin Media Server Stack";
      after = [ "docker.service" ];
      requires = [ "docker.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        WorkingDirectory = "/etc/homelab/jellyfin";
        ExecStartPre = [
          "${pkgs.coreutils}/bin/mkdir -p /var/lib/jellyfin/config"
          "${pkgs.coreutils}/bin/mkdir -p /var/lib/jellyfin/cache"
          "${pkgs.coreutils}/bin/mkdir -p /var/lib/jellyfin/media"
          "${pkgs.coreutils}/bin/chown -R 1000:1000 /var/lib/jellyfin"
        ];
        ExecStart = "${pkgs.docker-compose}/bin/docker-compose up -d";
        ExecStop = "${pkgs.docker-compose}/bin/docker-compose down";
        ExecReload = "${pkgs.docker-compose}/bin/docker-compose up -d --force-recreate";
        TimeoutStartSec = "300";
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
    
    # Dynamic DNS client
    ddclient        # Dynamic DNS client for Cloudflare integration
    
    # Secrets management (temporary - for initial setup)
    age             # Age encryption tool for agenix secrets
    
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
  
  # Allow unfree packages (needed for various packages)
  nixpkgs.config.allowUnfree = true;

  # Configure agenix secrets (will be enabled after key generation and secret creation)
  # age.secrets = {
  #   cloudflare-token = {
  #     file = ./secrets/cloudflare-token.age;
  #     owner = "ddclient";
  #     group = "ddclient";
  #   };
  #   homelab-domain = {
  #     file = ./secrets/homelab-domain.age;
  #     owner = "ddclient";
  #     group = "ddclient";
  #   };
  # };

  # NixOS state version
  system.stateVersion = stateVersions.nixos;

  # System timezone configuration
  time.timeZone = "Europe/Stockholm";

  # ========================================================================
  # HOMELAB DEPLOYMENT DOCUMENTATION
  # ========================================================================
  # This homelab uses Tailscale VPN + Cloudflare DynDNS for secure access
  # 
  # PHASE 1 - INITIAL DEPLOYMENT (current state):
  # 1. Deploy this configuration to Pi (ddclient disabled, no secrets)
  # 2. Set up Tailscale: `sudo tailscale up` and authenticate
  # 3. Verify basic functionality and SSH access via Tailscale
  # 
  # PHASE 2 - ENABLE DYNAMIC DNS (after initial deployment):
  # 1. Generate age key: `sudo age-keygen -o /etc/agenix/host.txt`
  # 2. Get public key: `sudo cat /etc/agenix/host.txt | grep "# public key:"`
  # 3. Update secrets/secrets.nix with the actual public key
  # 4. Create Cloudflare API token (Zone:Read + DNS:Edit permissions)
  # 5. Encrypt secrets:
  #    - `agenix -e secrets/cloudflare-token.age` (paste API token)
  #    - `agenix -e secrets/homelab-domain.age` (paste secret subdomain)
  # 6. Enable agenix imports and secrets in configuration.nix
  # 7. Enable ddclient service (set enable = true)
  # 8. Redeploy configuration
  # 9. Create DNS A record in Cloudflare for your secret subdomain
  #
  # ACCESS METHODS (MAXIMUM SECURITY):
  # LOCAL NETWORK ACCESS:
  # - SSH: `ssh fredrik@192.168.1.X` (Pi's local IP)
  # - Services: Direct access via local IP and ports
  #
  # REMOTE ACCESS VIA TAILSCALE (SECURE):
  # - SSH: `ssh fredrik@rpi5-homelab` (Tailscale hostname)
  # - Services via SSH tunnels:
  #   ssh -L 9000:localhost:9000 fredrik@rpi5-homelab  # Portainer
  #   ssh -L 8096:localhost:8096 fredrik@rpi5-homelab  # Jellyfin
  #   ssh -L 2283:localhost:2283 fredrik@rpi5-homelab  # Immich
  #   ssh -L 9090:localhost:9090 fredrik@rpi5-homelab  # Cockpit
  # - Then access via: http://localhost:9000, http://localhost:8096, etc.
  # - Or direct Tailscale access: http://rpi5-homelab:9000 (if enabled)
  #
  # MONITORING:
  # - Check ddclient status: `systemctl status ddclient`
  # - View ddclient logs: `journalctl -u ddclient -f`
  # - Check agenix secrets: `ls -la /run/agenix/` (should show decrypted secrets)
  # - Check Tailscale status: `tailscale status`
  # - View Tailscale logs: `journalctl -u tailscaled -f`
  # - Check fail2ban status: `systemctl status fail2ban`
  # - View banned IPs: `fail2ban-client status sshd`
  # - Unban an IP: `fail2ban-client set sshd unbanip <IP>`

  # TODO: Additional services that might be useful for a homelab:
  # - services.logrotate.enable = true; # Log management (enabled by default)
  # - services.cron.enable = true;      # Scheduled tasks (enabled by default)
  
  # TODO: Security considerations:
  # - Consider enabling passwordless sudo only for specific commands
  # - Consider setting up reverse proxy with SSL termination
}
