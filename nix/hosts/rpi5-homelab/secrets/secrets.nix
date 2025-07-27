# agenix secrets configuration for rpi5-homelab
# This file defines which secrets exist and which public keys can decrypt them
# 
# SETUP INSTRUCTIONS:
# 1. Generate age key on Pi: sudo age-keygen -o /etc/agenix/host.txt
# 2. Get public key: sudo cat /etc/agenix/host.txt | grep "# public key:"
# 3. Replace the placeholder below with your Pi's actual public key
# 4. Encrypt secrets: agenix -e cloudflare-token.age && agenix -e homelab-domain.age

let
  # Replace this with your Pi's actual public key from step 2 above
  rpi5-homelab = "age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
in
{
  # Cloudflare API token (Zone:Read + DNS:Edit permissions)
  "cloudflare-token.age".publicKeys = [ rpi5-homelab ];
  
  # Secret subdomain name (e.g., lab-k8s9x.averpil.com)
  # This keeps your actual domain private in the public repo
  "homelab-domain.age".publicKeys = [ rpi5-homelab ];
}