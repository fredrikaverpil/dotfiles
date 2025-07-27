# nix-config

## rpi5-homelab

The setup has taken inspiration from:

- [Raspberry Pi 5 on NixOS wiki](https://wiki.nixos.org/wiki/NixOS_on_ARM/Raspberry_Pi_5)
- [nvmd/nixos-raspberrypi](https://github.com/nvmd/nixos-raspberrypi)

### Prepare bootloader on Raspberry Pi 5

- Ensure NVMe SSD is connected.
- Boot Raspberry Pi OS from SD card.
- Update and upgrade: `sudo apt update && sudo apt full-upgrade -y`
- Enable PCIe: Edit `/boot/firmware/config.txt` and add `dtparam=pciex1`.
  Reboot.
- Verify NVMe detection: `lsblk` should show `/dev/nvme0n1`.
- Update Bootloader (EEPROM) - Crucial for NVMe Boot:
  `sudo rpi-eeprom-config --edit`
  - Change `BOOT_ORDER` to `0xf461` so either USB or SD Card takes precedence.
  - Add `PCIE_PROBE=1`.
  - Save and exit.
- Reboot.

The boot order can be translated like this:

- 4 = USB
- 6 = SD card
- 1 = NVMe

### Write NixOS installer onto NVMe SSD

On the rpi5, install Nix and enable flakes/nix-command:

```sh
sh <(curl -L https://nixos.org/nix/install) --daemon
```

Edit `/etc/nix/nix.conf` and add the following:

- `experimental-features`: add flakes support
- `trusted-users`, `extra-substituters` and `extra-trusted-public-keys`: needed
  for `nvmd/nixos-raspberrypi` build cache

```conf
experimental-features = nix-command flakes

trusted-users = root nixos fredrik
extra-substituters = https://nixos-raspberrypi.cachix.org
extra-trusted-public-keys = nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI=
```

Restart `nix-daemon` or reboot.

### Deploy with nixos-anywhere

From another develpment machine (e.g. macOS), `cd` into this repo. We will now
deploy the `flake.nix` using `nixos-anywhere`. This is a one-time step for the
very first installation which includes NVMe SSD partitioning.

Install nixos-anywhere on the machine:

```sh
nix profile add nixpkgs#nixos-anywhere
```

Now we need to enable `root` password on the rpi5. Make sure the rpi5 is running
the Raspberry OS from SD Card.

```sh
# SSH into rpi5
ssh root@raspberrypi.local

# Set root password
sudo passwd root
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sudo systemctl restart ssh

# Add Nix to system PATH permanently
echo 'export PATH="/root/.nix-profile/bin:$PATH"' >> /etc/bash.bashrc
echo 'source /root/.nix-profile/etc/profile.d/nix.sh' >> /etc/bash.bashrc

# Also add to /etc/environment for system-wide access
echo 'PATH="/root/.nix-profile/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"' >> /etc/environment

# Install nixos-install
nix-env -iA nixpkgs.nixos-install-tools

# Exit shell
exit
```

Now, let's eploy to the rpi5. From the development machine, run:

```sh
# Use disko to partition and format the storage
nixos-anywhere --flake .#rpi5-homelab --build-on remote --phases disko root@raspberrypi.local

# Build and deploy the NixOS configuration
nixos-anywhere --flake .#rpi5-homelab --build-on remote --phases install root@raspberrypi.local
```

Finally, remove the SD card from the rpi5 and reboot. It should now be possible
to SSH into the new system and change the password with `passwd`:

```sh
ssh fredrik@<ip-to-rpi5-homelab>
```

If you did not set the Wi-Fi password, log into the homelab locally and...

```sh
iwctl  # start iwctl in interactive mode
device list # get devices, such as 'wlan0'
station wlan0 scan # scan for networks
station wlan0 get-networks # show available networks
station wlan0 connect "YOUR_SSID" # connect (will prompt for password)
quit # exit iwctl

ip a # verify connection and get IP
systemctl is-enabled sshd  # check if sshd is enabled
systemctl is-active sshd  # check if sshd is running
```

### Post-Installation: Enable Dynamic DNS and VPN

The initial deployment includes basic services but has **ddclient (Dynamic DNS) disabled** and **agenix secrets commented out** until secrets are configured. This two-phase approach ensures you can deploy the basic system first, then add secrets functionality.

**IMPORTANT**: The configuration is set up for a two-phase deployment:
- **Phase 1**: Basic system with secrets disabled (safe to deploy immediately)
- **Phase 2**: Enable secrets after SSH keys are set up (requires manual steps)

#### What's Disabled in Fresh Installs

For security and deployment safety, these components are initially disabled:

```nix
# In configuration.nix - these are commented out/disabled for fresh installs:

# 1. ddclient service (around line 120)
ddclient = {
  enable = false;  # Will be enabled after secrets are set up
  # ...
};

# 2. agenix secrets configuration (around line 345)
# age.secrets = {
#   cloudflare-token = { ... };
#   homelab-domain = { ... };
# };

# 3. ddclient secret references (around line 125)
# passwordFile = config.age.secrets.cloudflare-token.path;
# domains = [ ... ];
```

This allows you to deploy the basic homelab infrastructure (Docker services, SSH, Tailscale, etc.) without needing secrets configured first.

#### 1. Set up Tailscale VPN (Secure Remote Access)

```sh
# Authenticate with Tailscale (run on the Pi)
sudo tailscale up

# Follow the authentication URL to connect your Pi to your Tailscale network
# Note the Tailscale hostname (e.g., rpi5-homelab) for remote SSH access
```

#### 2. Generate SSH Key for Secrets Management

```sh
# On the Pi, generate SSH key for agenix (if you don't already have one)
ssh-keygen -t ed25519 -C "fredrik@rpi5-homelab"
# Press Enter to accept default location (~/.ssh/id_ed25519)
# Press Enter for no passphrase (or add one if you prefer)

# Get your SSH public key (you'll need this for the next step)
cat ~/.ssh/id_ed25519.pub
# Example output: ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHRKV1VEpCLaXRaz99tWzgIs3cn1936K7i7tw/Dot+db fredrik@rpi5-homelab
```

#### 3. Update Secrets Configuration (on Development Machine)

```sh
# On your development machine, update the secrets configuration
cd nix/hosts/rpi5-homelab/secrets/
# Edit secrets.nix and replace the SSH public key with your Pi's actual SSH public key
```

#### 4. Create Cloudflare API Token

1. Go to [Cloudflare Dashboard → API Tokens](https://dash.cloudflare.com/profile/api-tokens)
2. Click "Create Token" → "Custom token"
3. Set permissions:
   - **Zone**: `Zone:Read`
   - **Zone**: `DNS:Edit`
4. Set zone resources:
   - **Include**: `Specific zone` → Select your domain
5. Copy the generated token

#### 5. Encrypt Secrets (on Pi)

```sh
# On the Pi, navigate to the secrets directory
cd ~/.dotfiles/nix/hosts/rpi5-homelab/secrets/

# Remove any existing .age files (if switching from age keys to SSH keys)
rm -f *.age

# Create Cloudflare API token secret
EDITOR=nano nix run github:ryantm/agenix -- -e cloudflare-token.age
# Paste your Cloudflare API token, save and exit (Ctrl+X, Y, Enter)

# Create domain secret (your chosen subdomain)
EDITOR=nano nix run github:ryantm/agenix -- -e homelab-domain.age  
# Paste your subdomain (e.g., lab-k8s9x.averpil.com), save and exit

# Verify both secrets were created and can be decrypted
ls -la *.age
nix run github:ryantm/agenix -- -d cloudflare-token.age  # Should show your token
```

#### 6. Enable Secrets in Configuration (on Development Machine)

After creating the secrets on the Pi, enable them in the configuration:

```sh
# On your development machine, edit the configuration
cd nix/hosts/rpi5-homelab/
nano configuration.nix

# Make these changes:
# 1. Uncomment the age.secrets configuration block (around line 345):
age.secrets = {
  cloudflare-token = {
    file = ./secrets/cloudflare-token.age;
    owner = "ddclient";
    group = "ddclient";
  };
  homelab-domain = {
    file = ./secrets/homelab-domain.age;
    owner = "ddclient";
    group = "ddclient";
  };
};

# 2. Enable ddclient (around line 120):
enable = true;  # Change from false

# 3. Uncomment the ddclient secrets (around line 125):
passwordFile = config.age.secrets.cloudflare-token.path;
domains = [ (lib.strings.removeSuffix "\n" (builtins.readFile config.age.secrets.homelab-domain.path)) ];

# Commit and push the changes
git add configuration.nix
git commit -m "Enable agenix secrets and ddclient"
git push
```

**Note**: The secrets (.age files) are only created on the Pi and are not committed to git for security.

#### 7. Create DNS Record in Cloudflare

1. Go to your Cloudflare DNS settings
2. Create an A record for your chosen subdomain pointing to any IP (ddclient will update it)
3. Example: `lab-k8s9x.averpil.com` → `1.1.1.1` (temporary)

#### 8. Deploy with Secrets Enabled

```sh
# On the Pi, pull the updated configuration and rebuild
cd ~/.dotfiles
git pull
sudo nixos-rebuild switch --flake .#rpi5-homelab

# Or from your development machine:
nixos-anywhere --flake .#rpi5-homelab --build-on remote --phases install root@<pi-ip>
```

#### 9. Verify Services

```sh
# Check ddclient status
systemctl status ddclient
journalctl -u ddclient -f

# Check Tailscale status  
tailscale status

# Check that secrets are decrypted
sudo ls -la /run/agenix/
```

### Access Methods

**Local Network:**
- SSH: `ssh fredrik@<pi-local-ip>`
- Services: Direct access via local IP and ports

**Remote Access via Tailscale (Secure):**
- SSH: `ssh fredrik@rpi5-homelab` (Tailscale hostname)
- Services via SSH tunnels:
  ```sh
  ssh -L 9000:localhost:9000 fredrik@rpi5-homelab  # Portainer
  ssh -L 8096:localhost:8096 fredrik@rpi5-homelab  # Jellyfin
  ssh -L 2283:localhost:2283 fredrik@rpi5-homelab  # Immich
  ssh -L 9090:localhost:9090 fredrik@rpi5-homelab  # Cockpit
  ```
- Then access via: http://localhost:9000, http://localhost:8096, etc.

**Internet Access (Optional):**
- Web services accessible via your secret subdomain (if ports 80/443 are forwarded)
- SSH is NOT exposed to internet (Tailscale only for security)

### Debugging

If you want to re-install while debugging, the partitions and data can be
erased. Run this from the rpi5:

```sh
sudo blkdiscard /dev/nvme0n1  # you will have to add the -f flag
```
