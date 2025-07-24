{ config, pkgs, lib, ... }: {
  # System services configuration for rpi5-homelab
  # Defines essential services for remote access, containerization, and system maintenance
  
  # SSH service for remote access
  # Essential for headless Raspberry Pi operation
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";  # Security: disable root login via SSH
    };
  };

  # Docker containerization platform
  # Enables running containerized applications and services
  virtualisation.docker = {
    enable = true;
  };

  # Network Time Protocol (NTP) synchronization
  # Ensures accurate system time for logging, certificates, and scheduled tasks
  # Critical for security and proper system operation
  services.timesyncd = {
    enable = true;
    # Uses systemd-timesyncd for lightweight NTP client functionality
  };
  
  # TODO: Additional services that might be useful for a homelab:
  # - services.fail2ban.enable = true;  # Intrusion prevention
  # - services.logrotate.enable = true; # Log management (enabled by default)
  # - services.cron.enable = true;      # Scheduled tasks (enabled by default)
}
