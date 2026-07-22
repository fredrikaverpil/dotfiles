{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  stateVersions = {
    nixos = "25.05";
  };
in {
  imports = [./restic.nix];

  # NixOS state version "25.05" - defines system configuration schema/compatibility
  # See flake.nix for actual package channel selection (stable vs unstable)
  # Reference: https://github.com/NixOS/nixpkgs/releases
  system.stateVersion = stateVersions.nixos;

  # Main configuration file for rpi5-homelab Raspberry Pi 5 system

  # ========================================================================
  # HOST CONFIGURATION
  # ========================================================================
  networking.hostName = "rpi5-homelab";

  nixpkgs.hostPlatform = "aarch64-linux";

  # Keep the legacy Raspberry Pi kernelboot behavior for now. The replacement
  # `kernel` bootloader stores NixOS generations under /boot/firmware/nixos;
  # upstream installer images use a 1024M firmware partition for that, while
  # this host currently declares a 512M firmware partition in hardware.nix.
  # Revisit migrating to `kernel` after checking/resizing /boot/firmware or
  # lowering boot.loader.raspberry-pi.configurationLimit.
  boot.loader.raspberry-pi.bootloader = "kernelboot-legacy-unsupported";

  time.timeZone = "Europe/Stockholm";

  host.users = {
    fredrik = {
      isAdmin = true;
      isPrimary = true; # Not used on Linux, but kept for consistency
      shell = "zsh";
      homeConfig = ./users/fredrik.nix;
      groups = ["networkmanager" "docker"];
      # SSH keys for secure access (RECOMMENDED: add your public key here)
      # This enables immediate key-based access on fresh installs
      # Generate key: ssh-keygen -t ed25519 -C "your-email@example.com"
      # Then add your ~/.ssh/id_ed25519.pub content below:
      sshKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIElRYEYxPt8po0TToz1U5bNZYJgnho7xIgApCh9DTfyn"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJKGKlggcQ6VquiOwiXz5505VnlzRXz6LWW8odDx6URk"
      ];
    };
  };

  # Enable systemd linger for fredrik so user services (e.g. the Claude Code
  # remote-control server) start on boot and keep running without an
  # interactive login session.
  users.users.fredrik.linger = true;

  # Wireless network configuration
  # Use NetworkManager with wpa_supplicant backend for better Pi stability under load
  networking.wireless.iwd.enable = false; # Disable iwd (less stable on Pi under load)
  networking.networkmanager = {
    enable = true;
    wifi.backend = "wpa_supplicant"; # Use wpa_supplicant instead of iwd for WiFi
    # Disable VPN plugins to avoid webkitgtk build on headless server
    # Default plugins (iodine-gnome, openconnect, etc.) pull in webkitgtk GUI dependencies
    # which are unnecessary for a headless homelab and cause expensive builds from source
    plugins = lib.mkForce [];
  };

  # Disable WiFi power management to prevent connection drops under high CPU load
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="wlan*", RUN+="${pkgs.iw}/bin/iw dev $name set power_save off"
  '';

  # WiFi watchdog: reconnects wlan if NM reports it disconnected, or if it
  # appears connected but pings to the default gateway fail. Escalates to a
  # brcmfmac driver reload if nmcli connect fails (targets the "never recovered"
  # wedged-driver case documented in https://github.com/fredrikaverpil/dotfiles/issues/204).
  systemd.services.wifi-watchdog = {
    description = "WiFi connectivity watchdog";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    serviceConfig = {
      Type = "oneshot";
      # Budget: ping(15s) + sleep(3s) + nmcli-connect(30s) + driver-reload(5s) +
      # nmcli-connect-retry(30s) = ~83s worst case; 120s gives comfortable headroom.
      TimeoutStartSec = "120s";
      ExecStart = pkgs.writeShellScript "wifi-watchdog" ''
        # Use nmcli for interface discovery to avoid picking up p2p-dev-wlan0
        iface=$(${pkgs.networkmanager}/bin/nmcli -t -f DEVICE,TYPE device | \
                ${pkgs.gawk}/bin/awk -F: '$2=="wifi"{print $1; exit}')
        [ -z "$iface" ] && exit 0

        reconnect() {
          echo "wifi-watchdog: reconnecting $iface..."
          ${pkgs.networkmanager}/bin/nmcli device disconnect "$iface" || true
          ${pkgs.coreutils}/bin/sleep 3
          # --wait 30 bounds the blocking connect so it always returns within budget.
          if ! ${pkgs.networkmanager}/bin/nmcli --wait 30 device connect "$iface"; then
            # nmcli connect failed — escalate to driver reload to recover a wedged
            # brcmfmac, which nmcli retries alone cannot fix.
            echo "wifi-watchdog: nmcli connect failed, reloading brcmfmac driver..."
            ${pkgs.kmod}/bin/modprobe -r brcmfmac || true
            ${pkgs.coreutils}/bin/sleep 2
            ${pkgs.kmod}/bin/modprobe brcmfmac || true
            ${pkgs.coreutils}/bin/sleep 3
            if ! ${pkgs.networkmanager}/bin/nmcli --wait 30 device connect "$iface"; then
              echo "wifi-watchdog: reconnect after driver reload failed, will retry on next tick"
            fi
          fi
        }

        state=$(${pkgs.networkmanager}/bin/nmcli -g GENERAL.STATE device show "$iface" 2>/dev/null)
        state_code="''${state%% *}"

        # NM device state codes: 100=connected, 40-90=connecting (leave alone),
        # everything else (0/10/20/30/110/120) = reconnect.
        case "$state_code" in
          100)
            # Connected — verify actual reachability via ping
            gateway=$(${pkgs.iproute2}/bin/ip route show dev "$iface" | \
                      ${pkgs.gawk}/bin/awk '/default/{print $3; exit}')
            [ -z "$gateway" ] && exit 0
            if ! ${pkgs.iputils}/bin/ping -c 3 -W 5 -I "$iface" "$gateway" >/dev/null 2>&1; then
              echo "wifi-watchdog: no ping response on $iface, reconnecting..."
              reconnect
            fi
            ;;
          4*|5*|6*|7*|8*|9*)
            # Association in progress — leave alone
            echo "wifi-watchdog: $iface connecting (state: $state), skipping"
            ;;
          *)
            # Disconnected, unavailable, failed, or unknown
            echo "wifi-watchdog: $iface not connected (state: $state), reconnecting..."
            reconnect
            ;;
        esac
      '';
    };
  };

  systemd.timers.wifi-watchdog = {
    description = "WiFi watchdog timer";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "1min";
    };
  };

  # Firewall configuration for homelab services
  # NOTE: for maximum security, do not expose SSH to internet, only via Tailscale VPN
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      # Local network + Tailscale access only
      22 # SSH - Local network and Tailscale VPN access only

      # Homelab service ports (local network access)
      9090 # Cockpit - System monitoring and administration
      8000 # Portainer - TCP tunnel server for Edge agents
      9000 # Portainer - HTTP port (legacy/optional)
      9443 # Portainer - HTTPS port (primary)
      3001 # Uptime Kuma - Service monitoring dashboard
      2283 # Immich - Photo management web interface
      8096 # Jellyfin - Media server web interface
    ];

    allowedUDPPorts = [
    ];

    # Allow Tailscale traffic (+ matches any interface starting with "tailscale")
    trustedInterfaces = ["tailscale+"];
  };

  host.extraServices = {
    # SSH service for remote access
    # Accessible via local network and Tailscale VPN only (not internet-exposed)
    openssh = {
      enable = true;
      ports = [22]; # Standard SSH port (safe since not internet-exposed)
      settings = {
        PermitRootLogin = "no"; # Security: disable root login via SSH
        PasswordAuthentication = true; # Safe for local network + Tailscale access
        KbdInteractiveAuthentication = false; # Security: disable keyboard-interactive auth
        PubkeyAuthentication = true; # Enable SSH key authentication (default, but explicit)
      };
    };

    # Network Time Protocol (NTP) synchronization
    timesyncd = {
      enable = true;
    };

    # Avahi service for mDNS/Bonjour network discovery
    # Allows the Pi to be accessible via rpi5-homelab.local on the local network
    avahi = {
      enable = true;
      nssmdns4 = true; # Enable mDNS resolution in NSS for IPv4
      publish = {
        enable = true;
        addresses = true; # Publish IP addresses via mDNS
        workstation = true; # Announce as a workstation for better discovery
      };
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
      bantime = "1h"; # Ban duration: 1 hour
      maxretry = 5; # Increased to 5 since only local network access
      ignoreIP = [
        "127.0.0.1/8" # Never ban localhost
        "192.168.0.0/16" # Never ban local network (adjust if needed)
        "10.0.0.0/8" # Never ban private networks
        "172.16.0.0/12" # Never ban private networks
        "100.64.0.0/10" # Never ban Tailscale network
      ];
      jails = {
        # SSH jail configuration
        sshd = {
          settings = {
            enabled = true;
            port = "22"; # Standard SSH port (local + Tailscale only)
            findtime = "10m"; # Time window to look for failures: 10 minutes
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
          AllowUnencrypted = true; # Allow HTTP for local network access
          Origins = lib.mkForce "http://rpi5-homelab.local:9090 http://localhost:9090";
        };
      };
    };
  };

  # Docker containerization platform
  virtualisation.docker = {
    enable = true;
  };

  # Host-specific system users
  users.users.cloudflared = {
    isSystemUser = true;
    group = "cloudflared";
    description = "Cloudflare Tunnel user";
  };
  users.groups.cloudflared = {};

  # ========================================================================
  # HOMELAB DOCKER SERVICES
  # ========================================================================
  # Copy docker-compose files and scripts to system locations
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
      after = ["docker.service"];
      requires = ["docker.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        WorkingDirectory = "/etc/homelab/portainer";
        ExecStart = "${pkgs.docker-compose}/bin/docker-compose up -d";
        ExecStop = "${pkgs.docker-compose}/bin/docker-compose down";
        ExecReload = "${pkgs.docker-compose}/bin/docker-compose up -d --force-recreate";
        TimeoutStartSec = "300";
      };
      wantedBy = ["multi-user.target"];
    };

    homelab-uptime-kuma = {
      description = "Homelab Uptime Kuma Service Monitoring Stack";
      after = ["docker.service"];
      requires = ["docker.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        WorkingDirectory = "/etc/homelab/uptime-kuma";
        ExecStart = "${pkgs.docker-compose}/bin/docker-compose up -d";
        ExecStop = "${pkgs.docker-compose}/bin/docker-compose down";
        ExecReload = "${pkgs.docker-compose}/bin/docker-compose up -d --force-recreate";
        TimeoutStartSec = "300";
      };
      wantedBy = ["multi-user.target"];
    };

    # Cloudflare Tunnel service
    cloudflared = {
      description = "Cloudflare Tunnel";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      # Only start if tunnel token exists - prevents boot failures
      unitConfig.ConditionPathExists = "/etc/cloudflared/tunnel.json";
      serviceConfig = {
        Type = "simple";
        User = "cloudflared";
        Group = "cloudflared";
        # Simplified ExecStart since ConditionPathExists ensures file exists
        ExecStart = "${pkgs.bash}/bin/bash -c 'TOKEN=$(cat /etc/cloudflared/tunnel.json); exec ${pkgs.cloudflared}/bin/cloudflared tunnel run --token \"$$TOKEN\"'";
        Restart = "always";
        RestartSec = "30";
        # Directory management
        StateDirectory = "cloudflared";
        StateDirectoryMode = "0755";
        # Security settings
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadOnlyPaths = ["/etc/cloudflared"];
      };
      # Start automatically - but only if ConditionPathExists is satisfied
      wantedBy = ["multi-user.target"];
    };

    homelab-immich = {
      description = "Homelab Immich Photo Management Stack";
      after = ["docker.service"];
      requires = ["docker.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        WorkingDirectory = "/etc/homelab/immich";
        ExecStartPre = [
          "${pkgs.coreutils}/bin/mkdir -p /mnt/homelab-data/services/immich/library"
          "${pkgs.coreutils}/bin/mkdir -p /mnt/homelab-data/services/immich/postgres"
          "${pkgs.coreutils}/bin/chown -R ${toString config.users.users.fredrik.uid}:${toString config.users.groups.users.gid} /mnt/homelab-data/services/immich"
        ];
        ExecStart = "${pkgs.docker-compose}/bin/docker-compose up -d";
        ExecStop = "${pkgs.docker-compose}/bin/docker-compose down";
        ExecReload = "${pkgs.docker-compose}/bin/docker-compose up -d --force-recreate";
        TimeoutStartSec = "600"; # Immich takes longer to start (ML models, etc.)
      };
      wantedBy = ["multi-user.target"];
    };

    homelab-jellyfin = {
      description = "Homelab Jellyfin Media Server Stack";
      after = ["docker.service"];
      requires = ["docker.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        WorkingDirectory = "/etc/homelab/jellyfin";
        ExecStartPre = [
          "${pkgs.coreutils}/bin/mkdir -p /mnt/homelab-data/services/jellyfin/config"
          "${pkgs.coreutils}/bin/mkdir -p /mnt/homelab-data/services/jellyfin/cache"
          "${pkgs.coreutils}/bin/mkdir -p /mnt/homelab-data/services/jellyfin/media"
          "${pkgs.coreutils}/bin/chown -R ${toString config.users.users.fredrik.uid}:${toString config.users.groups.users.gid} /mnt/homelab-data/services/jellyfin"
        ];
        ExecStart = "${pkgs.docker-compose}/bin/docker-compose up -d";
        ExecStop = "${pkgs.docker-compose}/bin/docker-compose down";
        ExecReload = "${pkgs.docker-compose}/bin/docker-compose up -d --force-recreate";
        TimeoutStartSec = "300";
      };
      wantedBy = ["multi-user.target"];
    };
  };

  # ========================================================================
  # HOST-SPECIFIC EXTENSIONS
  # ========================================================================
  # Host-specific system packages for rpi5-homelab
  host.extraSystemPackages = with pkgs;
    [
      # Essential system administration tools
      # These are kept minimal as most tools are managed via home-manager

      # System recovery and maintenance tools
      curl # Network tool for downloading/API calls
      wget # File download utility

      # Container tools for homelab services
      docker-compose # Container orchestration

      # Backup tools
      restic # Backup tool for Immich and other services

      # Cloudflare tools
      cloudflared # Cloudflare Tunnel client

      # Hardware-specific utilities for Raspberry Pi
      # These may be provided by nixos-raspberrypi modules
    ]
    ++ (with pkgs.rpi or {}; [
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
  system.nixos.tags = let
    cfg = config.boot.loader.raspberry-pi;
  in [
    "raspberry-pi-${cfg.variant}" # e.g., "raspberry-pi-5"
    cfg.bootloader # Bootloader type
    config.boot.kernelPackages.kernel.version # Kernel version
  ];

  # Allow unfree packages (needed for various packages)
  nixpkgs.config.allowUnfree = true;

  # TODO: Additional services that might be useful for a homelab:
  # - services.logrotate.enable = true; # Log management (enabled by default)
  # - services.cron.enable = true;      # Scheduled tasks (enabled by default)
}
