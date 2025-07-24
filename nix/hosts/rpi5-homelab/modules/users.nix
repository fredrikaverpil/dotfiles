{ config, pkgs, lib, ... }: {
  # User account configuration for rpi5-homelab
  # Defines user accounts, shell preferences, and security settings
  
  # Enable zsh system-wide for consistent shell experience
  # Matches the shell configuration used on macOS machines
  programs.zsh.enable = true;

  # Primary user account configuration
  users.users.fredrik = {
    isNormalUser = true;  # Regular user account (not system user)
    
    # Group memberships for system access and permissions
    extraGroups = [ 
      "wheel"          # Administrative privileges (sudo access)
      "networkmanager" # Network configuration permissions
      "docker"         # Docker daemon access for container management
    ];
    
    # Security: Change this password immediately after first login
    initialPassword = "changeme";
    
    # Set zsh as default shell to match other machines in the setup
    shell = pkgs.zsh;
    
    # SSH public key authentication (recommended for security)
    # Uncomment and add your SSH public keys for passwordless login
    # openssh.authorizedKeys.keys = [
    #   "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5... your-key-here"
    #   "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAB... another-key-here"
    # ];
  };

  # Sudo configuration for administrative access
  # Allow wheel group members to use sudo without password prompt
  # This is convenient for automation but consider security implications
  security.sudo.wheelNeedsPassword = false;
  
  # TODO: Security considerations:
  # - Consider enabling passwordless sudo only for specific commands
  # - Use SSH keys instead of passwords for remote access
}
