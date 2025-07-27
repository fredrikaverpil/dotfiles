# agenix secrets configuration for rpi5-homelab
# This file defines which secrets exist and which public keys can decrypt them
# 
# SETUP INSTRUCTIONS:
# 1. Generate SSH key on Pi: ssh-keygen -t ed25519 -C "fredrik@rpi5-homelab"
# 2. Get public key: cat ~/.ssh/id_ed25519.pub
# 3. Update the public key below
# 4. Encrypt secrets: agenix -e cloudflare-token.age && agenix -e homelab-domain.age

let
  # SSH public key for rpi5-homelab
  rpi5-homelab = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHRKV1VEpCLaXRaz99tWzgIs3cn1936K7i7tw/Dot+db fredrik@rpi5-homelab";
in
{
  # Cloudflare API token (Zone:Read + DNS:Edit permissions)
  "cloudflare-token.age".publicKeys = [ rpi5-homelab ];
  
  # Secret subdomain name (e.g., lab-k8s9x.averpil.com)
  # This keeps your actual domain private in the public repo
  "homelab-domain.age".publicKeys = [ rpi5-homelab ];
}