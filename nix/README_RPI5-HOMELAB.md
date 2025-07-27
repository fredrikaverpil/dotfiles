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

The configuration uses **conditional secrets management** that automatically adapts based on whether secret files exist. This two-phase approach ensures you can deploy the basic system first, then add secrets functionality without manual configuration changes.

**IMPORTANT**: The configuration automatically detects secret files:
- **Phase 1**: Basic system (no secrets = services disabled automatically)
- **Phase 2**: Full functionality (secrets present = services enabled automatically)

#### How Conditional Configuration Works

The system uses `builtins.pathExists` to check for secret files and automatically enables/disables services:

```nix
# In configuration.nix - automatic conditional logic:
let
  cloudflareTokenExists = builtins.pathExists ./secrets/cloudflare-token.age;
  homelabDomainExists = builtins.pathExists ./secrets/homelab-domain.age;
  ddclientSecretsExist = cloudflareTokenExists && homelabDomainExists;
in {
  # ddclient automatically enabled only when both secrets exist
  ddclient = {
    enable = ddclientSecretsExist;  # Automatic based on secret files
    passwordFile = lib.mkIf cloudflareTokenExists config.age.secrets.cloudflare-token.path;
    domains = lib.mkIf homelabDomainExists [ ... ];
  };

  # Secrets only configured when files exist
  age.secrets = {
    cloudflare-token = lib.mkIf cloudflareTokenExists { ... };
    homelab-domain = lib.mkIf homelabDomainExists { ... };
  };
}
```

This means:
- **Fresh installs**: No secrets = ddclient disabled, basic services work
- **With secrets**: Both secrets present = ddclient enabled automatically
- **No manual configuration changes needed** between phases

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

#### 6. Deploy with Secrets (Automatic Configuration)

After creating the secrets on the Pi, the configuration will automatically detect them and enable ddclient:

```sh
# The configuration automatically detects the presence of secret files:
# - cloudflare-token.age exists → cloudflare token secret configured
# - homelab-domain.age exists → domain secret configured  
# - Both exist → ddclient service enabled automatically
# - Either missing → ddclient remains disabled

# No manual configuration changes needed!
# The conditional logic handles everything automatically.
```

**Note**: The secrets (.age files) are only created on the Pi and are not committed to git for security. The configuration automatically adapts to their presence.

**Benefits of Conditional Configuration:**
- ✅ **Safe deployment**: Fresh installs work immediately without secrets
- ✅ **No manual edits**: Configuration automatically adapts to secret presence  
- ✅ **Gradual setup**: Add secrets when ready, services enable automatically
- ✅ **Consistent config**: Same configuration works for all deployment phases
- ✅ **Error prevention**: No risk of forgetting to enable services after adding secrets

#### 7. Create DNS Record in Cloudflare

1. Go to your Cloudflare DNS settings
2. Create an A record for your chosen subdomain pointing to any IP (ddclient will update it)
3. Example: `lab-k8s9x.averpil.com` → `1.1.1.1` (temporary)

#### 8. Deploy with Automatic Secret Detection

```sh
# On the Pi, rebuild the system (secrets will be detected automatically)
cd ~/.dotfiles
sudo nixos-rebuild switch --flake .#rpi5-homelab

# Or from your development machine:
nixos-anywhere --flake .#rpi5-homelab --build-on remote --phases install root@<pi-ip>

# The system will automatically:
# 1. Detect the presence of cloudflare-token.age and homelab-domain.age
# 2. Enable ddclient service since both secrets exist
# 3. Configure the secrets for ddclient to use
# 4. Start ddclient with the proper credentials
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
