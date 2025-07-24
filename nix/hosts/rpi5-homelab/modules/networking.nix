{ config, pkgs, lib, ... }: {
  # Network configuration for rpi5-homelab
  # Sets up hostname, wireless connectivity, and network discovery
  
  # Set system hostname for network identification
  networking.hostName = "rpi5-homelab";

  # Wireless network configuration
  # Disable legacy wpa_supplicant in favor of modern iwd
  networking.wireless.enable = false;  # Disable wpa_supplicant
  networking.wireless.iwd.enable = true;  # Enable Intel's iwd for better WiFi management

  # Avahi service for mDNS/Bonjour network discovery
  # Allows the Pi to be accessible via rpi5-homelab.local on the local network
  # Essential for headless operation and easy SSH access
  services.avahi = {
    enable = true;
    nssmdns4 = true;  # Enable mDNS resolution in NSS for IPv4
    publish = {
      enable = true;
      addresses = true;     # Publish IP addresses via mDNS
      workstation = true;   # Announce as a workstation for better discovery
    };
  };
}
