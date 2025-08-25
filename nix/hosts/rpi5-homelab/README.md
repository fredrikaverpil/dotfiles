# rpi5-homelab

The setup has taken inspiration from:

- [Raspberry Pi 5 on NixOS wiki](https://wiki.nixos.org/wiki/NixOS_on_ARM/Raspberry_Pi_5)
- [nvmd/nixos-raspberrypi](https://github.com/nvmd/nixos-raspberrypi)

## Hardware

- [Raspberry Pi 5](https://www.raspberrypi.com/), 16 GB RAM
- [Argon One V5 Dual M.2 NVMe](https://argon40.com/products/argon-one-v5-case-for-raspberry-pi-5)
- [Crucial P3 Plus PCIe Gen4 NVMe M.2 Internal SSD](https://www.crucial.com/products/ssd/crucial-p3-plus-ssd),
  1TB + 2TB
- 64 GB SD Card with Raspberry Pi OS 64-bit

## Preparations

### Install Argon One V5 Dual M.2 NVMe case

> [!WARNING]
>
> It seems the Argon installer bash script adds a bunch of `dtparams` that
> messes up power consumption to NVMe SSDs and/or Wi-Fi. Do NOT install it.

Install the Argon V5 Dual M.2 NVMe case. The installation explicitly mentions:

```ini
dtoverlay=dwc2,dr_mode=host
```

All in all, this is what I have in the `[all]` section:

```ini
[all]
dtparam=nvme
dtparam=pciex1
dtoverlay=dwc2,dr_mode=host
```

### Prepare bootloader on Raspberry Pi 5

- Ensure NVMe SSD is connected intended for the NixOS system.
- Boot Raspberry Pi OS from SD card.
- Update and upgrade: `sudo apt update && sudo apt full-upgrade -y`
- Enable PCIe: Edit `/boot/firmware/config.txt` and make sure `dtparam=pciex1`
  is in there. Reboot.
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

On the rpi5, in Raspberry OS booted off the SD card, install Nix and enable
flakes/nix-command:

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

## Deploy with nixos-anywhere

From another develpment machine (e.g. macOS), `cd` into this repo. We will now
deploy the `flake.nix` using `nixos-anywhere`. This is a one-time step for the
very first installation which includes NVMe SSD partitioning.

Install nixos-anywhere on the machine:

```sh
nix profile add nixpkgs#nixos-anywhere
```

Now we need to enable `root` password on the rpi5. Make sure the rpi5 is running
the Raspberry OS from SD Card. From the rpi5:

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

Now, let's install NixOS onto the rpi5 remotely. From the development machine,
run:

```sh
# Use disko to partition and format the storage
nixos-anywhere --flake .#rpi5-homelab --build-on remote --phases disko root@raspberrypi.local

# Note: use `gparted` on the rpi5 to e.g. fully remove partitions.

# Build and deploy the NixOS configuration
nixos-anywhere --flake .#rpi5-homelab --build-on remote --phases install root@raspberrypi.local
```

Finally, remove the SD card from the rpi5 and reboot. It should now be possible
to SSH into the new system:

```sh
ssh fredrik@<ip-to-rpi5-homelab>
```

Change the password using `passwd`:

If you did not set the Wi-Fi password, log into the homelab locally and...

```sh
# Using NetworkManager with wpa_supplicant backend
nmcli device wifi list # scan and show available networks
nmcli device wifi connect "YOUR_SSID" password "YOUR_PASSWORD"

# Alternative: use text-based UI for network configuration
nmtui

# Verify connection
ip a # verify connection and get IP
systemctl is-enabled sshd  # check if sshd is enabled
systemctl is-active sshd  # check if sshd is running
```

## Post-install setup

### `~/.nix-profile` symlink

If the `~/.nix-profile` symlink is broken, re-create it and point it to
home-manager on Linux:

```sh
rm ~/.nix-profile && ln -s ~/.local/state/nix/profiles/home-manager/home-path ~/.nix-profile
```

> [!NOTE]
>
> On macOS, `~/.nix-profile` points to `~/.local/state/nix/profiles/profile`.
>
> This discrepancy is because of how `home-manager.useUserPackages` setting
> differs on the systems. Setting it to `true` isolates home-manager packages
> from system packages and this is the "recommended" approach as it avoids
> potential conflicts between system and user packages.

### Second NVMe SSD for media storage

```sh
# Check so drive is visible
lsblk

sudo parted /dev/nvme1n1 mklabel gpt
sudo parted /dev/nvme1n1 mkpart primary ext4 0% 100%
sudo mkfs.ext4 -L "homelab-data" /dev/nvme1n1p1

# Check outcome
lsblk -f
```

After mounting (via `nixos-rebuild switch`:

```sh
# We will assume containers will run as `$(id fredrik)`
sudo chown -R fredrik:users /mnt/homelab-data
```

### Configure Tailscale VPN

After the system is deployed and running, set up Tailscale for secure remote
access:

```sh
# SSH into the Pi (local network)
ssh fredrik@<ip-to-rpi5-homelab>

# Set up Tailscale VPN
sudo tailscale up

# Follow the authentication URL provided
# Verify Tailscale is working
tailscale status
```

### Access Methods

**LOCAL NETWORK ACCESS:**

- SSH: `ssh fredrik@192.168.1.X` (Pi's local IP)
- Services: Direct access via local IP and ports

**REMOTE ACCESS VIA TAILSCALE (SECURE):**

- SSH: `ssh fredrik@rpi5-homelab` (Tailscale hostname)
- Services via SSH tunnels:

  ```sh
  ssh -L 9000:localhost:9000 fredrik@rpi5-homelab  # Portainer
  ssh -L 8096:localhost:8096 fredrik@rpi5-homelab  # Jellyfin
  ssh -L 2283:localhost:2283 fredrik@rpi5-homelab  # Immich
  ssh -L 9090:localhost:9090 fredrik@rpi5-homelab  # Cockpit
  ```

- Then access via: http://localhost:9000, http://localhost:8096, etc.
- Or direct Tailscale access: http://rpi5-homelab:9000 (if enabled)

**MONITORING:**

- Check Tailscale status: `tailscale status`
- View Tailscale logs: `journalctl -u tailscaled -f`
- Check fail2ban status: `systemctl status fail2ban`
- View banned IPs: `fail2ban-client status sshd`
- Unban an IP: `fail2ban-client set sshd unbanip <IP>`

### Configure Cloudflare Tunnel

The homelab uses Cloudflare Tunnel to securely expose services like Immich to
the internet. This provides HTTPS, DDoS protection, and hides your home IP
address.

#### Create Cloudflare Tunnel

1. **Log into Cloudflare Dashboard**:
   - Go to your domain → **Zero Trust** → **Networks** → **Tunnels**
   - Click **Create a tunnel**

2. **Configure Tunnel**:
   - Name: `homelab-tunnel`
   - Choose **Cloudflared** connector
   - Copy the tunnel token (starts with `eyJ...`)

3. **Add Public Hostname**:
   - Subdomain: `my-service`
   - Domain: `yourdomain.com`
   - Service: `HTTP://localhost:1234`
   - Save tunnel

#### Configure Pi

1. **Create tunnel directory**:

   ```sh
   sudo mkdir -p /etc/cloudflared
   sudo chmod 755 /etc/cloudflared
   ```

2. **Save tunnel credentials**:

   ```sh
   # Create tunnel.json with your tunnel token
   sudo nano /etc/cloudflared/tunnel.json
   ```

   Paste the tunnel token JSON (from Cloudflare dashboard)

3. **Set domain**:

   ```sh
   # Replace with your actual domain
   echo "yourdomain.com" | sudo tee /etc/cloudflared/domain
   ```

4. **Set permissions**:

   ```sh
   sudo chmod 640 /etc/cloudflared/tunnel.json
   sudo chmod 644 /etc/cloudflared/domain
   sudo chown root:cloudflared /etc/cloudflared/tunnel.json
   sudo chown root:root /etc/cloudflared/domain
   ```

#### Start Service

```sh
# Enable tunnel service
sudo systemctl enable cloudflared

# Start tunnel service
sudo systemctl start cloudflared

# Check status
sudo systemctl status cloudflared

# View logs
sudo journalctl -u cloudflared -f
```

#### Access Your Services

- Go to `https://my-service.yourdomain.com`
- Automatic HTTPS with Cloudflare certificate
- Works from anywhere on the internet
- No VPN required for users

#### Troubleshooting

- **Service won't start**: Check `/etc/cloudflared/tunnel.json` exists and has
  valid JSON
- **Domain errors**: Verify `/etc/cloudflared/domain` contains your domain name
- **Connection issues**: Check tunnel status in Cloudflare dashboard
- **502 errors**: Ensure Immich is running on port 2283

#### Security Benefits

- **IP Hidden**: Home IP is not exposed
- **DDoS Protection**: Cloudflare absorbs attacks
- **No Port Forwarding**: Router stays secure
- **Automatic HTTPS**: SSL certificates managed by Cloudflare
- **Access Control**: Optional authentication via Cloudflare Access

## Backup Configuration

Automated restic backups for Immich to Hetzner Storage Box using two separate
services: backup upload and validation.

**Setup**:

```sh
~/.dotfiles/nix/hosts/rpi5-homelab/scripts/setup-restic-backup.sh
```

The script will ask you for the Uptime Kuma push keys for backup and
restore/validation respectively, so you will have to set those up as part of
this process. Example settings:

- Monitor type: Push
- Heartbeat interval: 604800 (7 days)
- Retries: 1
- Heartbeat retry: 86400 (1 day)
- Notification:
  [Gmail SMTP](https://developers.google.com/workspace/gmail/imap/imap-smtp)

After completing the setup script steps, run the following from the
rpi5-homelab:

```sh
# Copy key (requires Hetzner box password) onto Hetzner box
cat ~/.ssh/id_ed25519.pub | ssh -p23 uXXXXX@uXXXXX.your-storagebox.de install-ssh-key

# Connect to test the SSH connection (optional)
ssh uXXXXX@uXXXXX.your-storagebox.de -p 23
exit  # exit back to rpi5-homelab

# Initialize restic repo with encryption password
sudo bash -c 'restic init --repo "$(grep RESTIC_REPOSITORY /etc/restic/immich-config | cut -d= -f2)" --password-file /etc/restic/immich-password'
```

### Manual Operations

**Run backup**:

```sh
sudo systemctl start restic-backups-immich.service
```

**Run validation**:

```sh
sudo systemctl start restic-validation-immich.service
```

**Check status**:

```sh
# Backup service
sudo systemctl status restic-backups-immich.service
sudo systemctl status restic-backups-immich.timer

# Validation service
sudo systemctl status restic-validation-immich.service
sudo systemctl status restic-validation-immich.timer
```

**View logs**:

```sh
# Backup logs
sudo journalctl -u restic-backups-immich.service --since "today" --no-pager
sudo journalctl -u restic-backups-immich.service -f

# Validation logs
sudo journalctl -u restic-validation-immich.service --since "today" --no-pager
sudo journalctl -u restic-validation-immich.service -f

# Both services
sudo journalctl -u restic-backups-immich.service -u restic-validation-immich.service --since "today" --no-pager
```

**List snapshots**:

```sh
sudo -E restic -r $(grep RESTIC_REPOSITORY /etc/restic/immich-config | cut -d= -f2) --password-file /etc/restic/immich-password snapshots
```

### Validation & Testing

**Test backup integrity**:

```sh
sudo /etc/homelab/scripts/validate-immich.sh --validate
sudo /etc/homelab/scripts/validate-immich.sh --validate --snapshot abc123
```

**Download backup files**:

```sh
sudo /etc/homelab/scripts/validate-immich.sh --save
sudo /etc/homelab/scripts/validate-immich.sh --save --snapshot abc123
```

### Restore Operations

**Production restore** (DESTRUCTIVE):

```sh
sudo /etc/homelab/scripts/validate-immich.sh --restore
sudo /etc/homelab/scripts/validate-immich.sh --restore --snapshot abc123
```

### Troubleshooting

**Check repository health**:

```sh
sudo -E restic -r $(grep RESTIC_REPOSITORY /etc/restic/immich-config | cut -d= -f2) --password-file /etc/restic/immich-password check
```

**Service-specific issues**:

```sh
# Backup service issues
sudo journalctl -u restic-backups-immich.service --since "today" --no-pager

# Validation service issues
sudo journalctl -u restic-validation-immich.service --since "today" --no-pager

# Manual validation test
sudo /etc/homelab/scripts/validate-immich.sh --validate
```

**Common issues**:

- **Backup fails**: Check disk space and Hetzner connectivity
- **Validation fails**: Check PostgreSQL container availability, run manual test
- **Both services fail**: Check restic configuration and network connectivity
- **Partial success**: Backup works but validation fails - investigate
  validation logs
