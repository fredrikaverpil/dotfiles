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

The initial deployment includes basic services but has ddclient (Dynamic DNS) disabled until secrets are configured. Follow these steps to enable full functionality:

#### 1. Set up Tailscale VPN (Secure Remote Access)

```sh
# Authenticate with Tailscale (run on the Pi)
sudo tailscale up

# Follow the authentication URL to connect your Pi to your Tailscale network
# Note the Tailscale hostname (e.g., rpi5-homelab) for remote SSH access
```

#### 2. Generate Age Encryption Key (for Secrets Management)

```sh
# On the Pi, generate the age key for agenix secrets
nix-shell -p age
sudo mkdir -p /etc/agenix
sudo age-keygen -o /etc/agenix/host.txt

# Get the public key (you'll need this for the next step)
sudo cat /etc/agenix/host.txt | grep "# public key:"
# Example output: age1e6y326s76ypwx8px2jdjvjhznejecjyjefvedt9wlrtrj6zak9ysmr6evr
```

#### 3. Update Secrets Configuration (on Development Machine)

```sh
# On your development machine, update the secrets configuration
cd nix/hosts/rpi5-homelab/secrets/
# Edit secrets.nix and replace the placeholder with your Pi's actual public key
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

#### 5. Encrypt Secrets

```sh
# From the secrets directory on your development machine
cd nix/hosts/rpi5-homelab/secrets/

# Create Cloudflare API token secret
EDITOR=nano nix run github:ryantm/agenix -- -e cloudflare-token.age
# Paste your Cloudflare API token, save and exit (Ctrl+X, Y, Enter)

# Create domain secret (your chosen subdomain)
EDITOR=nano nix run github:ryantm/agenix -- -e homelab-domain.age  
# Paste your subdomain (e.g., lab-k8s9x.averpil.com), save and exit

# Verify both secrets were created
ls -la *.age
```

#### 6. Enable Secrets in Configuration (After Deployment)

After deploying to the Pi, you'll need to enable the secrets:

```sh
# SSH to the Pi
ssh fredrik@<pi-ip>
cd ~/.dotfiles

# Edit nix/hosts/rpi5-homelab/configuration.nix
# Uncomment the age.secrets configuration block (lines ~345-356)
# Enable ddclient by changing enable = false to enable = true (line ~120)

# Rebuild the configuration
sudo nixos-rebuild switch --flake .#rpi5-homelab
```

**Note**: You cannot test the build locally with secrets enabled since the encrypted files are only decryptable on the target machine with the private key.

#### 7. Create DNS Record in Cloudflare

1. Go to your Cloudflare DNS settings
2. Create an A record for your chosen subdomain pointing to any IP (ddclient will update it)
3. Example: `lab-k8s9x.averpil.com` → `1.1.1.1` (temporary)

#### 8. Redeploy Configuration

```sh
# From your development machine, redeploy with secrets enabled
nixos-anywhere --flake .#rpi5-homelab --build-on remote --phases install root@<pi-ip>

# Or if you can SSH to the Pi directly:
ssh fredrik@<pi-ip>
cd ~/.dotfiles
sudo nixos-rebuild switch --flake .#rpi5-homelab
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
