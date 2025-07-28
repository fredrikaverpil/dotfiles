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

Now, let's install the rpi5. From the development machine, run:

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

### Configure Dynamic DNS with Cloudflare

The homelab includes ddclient for automatic DNS updates when your public IP changes. This enables accessing your homelab services via domain names even with a dynamic IP.

#### Setup Cloudflare API Credentials

1. **Get Cloudflare API Key**:
   - Log into Cloudflare dashboard
   - Go to "My Profile" → "API Tokens"
   - Create a custom token with:
     - Permissions: `Zone:Zone:Read`, `Zone:DNS:Edit`
     - Zone Resources: Include your domain zone
   - Or use Global API Key (less secure but simpler)

2. **Get Zone ID**:
   - In Cloudflare dashboard, select your domain
   - Copy the Zone ID from the right sidebar

3. **Create secrets file on the Pi**:
   ```sh
   sudo mkdir -p /etc/ddclient
   sudo touch /etc/ddclient/secrets.env
   sudo chmod 600 /etc/ddclient/secrets.env
   sudo chown root:root /etc/ddclient/secrets.env
   ```

4. **Add your credentials** to `/etc/ddclient/secrets.env`:
   ```env
   # Cloudflare account email
   CLOUDFLARE_EMAIL=your-email@example.com
   
   # Cloudflare API key (either custom token or global API key)
   CLOUDFLARE_API_KEY=your-api-key-here
   
   # Cloudflare zone (your domain)
   CLOUDFLARE_ZONE=yourdomain.com
   
   # Hostname/subdomain to update (without the domain)
   CLOUDFLARE_HOSTNAME=homelab
   ```

#### Service Management

After creating the secrets file, enable and start the ddclient service:

```sh
# Enable ddclient service to start on boot
sudo systemctl enable ddclient

# Start ddclient service
sudo systemctl start ddclient

# Check service status
sudo systemctl status ddclient

# View logs
sudo journalctl -u ddclient -f

# Test configuration manually (optional)
sudo ddclient -daemon=0 -debug -verbose -noquiet -file /var/run/ddclient/ddclient.conf
```

**Note**: The ddclient service is configured to NOT start automatically on fresh installs. You must create the secrets file first, then manually enable the service. This prevents boot failures when the secrets file is missing.

#### Verification

1. **Check DNS propagation**:
   ```sh
   nslookup homelab.yourdomain.com
   dig homelab.yourdomain.com
   ```

2. **Verify IP matches**:
   ```sh
   curl -s checkip.dyndns.com | grep -o '[0-9.]*'
   ```

#### Troubleshooting

- **Service fails to start**: Check `/etc/ddclient/secrets.env` permissions and syntax
- **DNS not updating**: Verify API key permissions and zone ID
- **Logs show authentication errors**: Double-check email and API key
- **IP detection issues**: Test with `curl checkip.dyndns.com`

The ddclient service will automatically:
- Check for IP changes every 5 minutes
- Update DNS records when changes are detected  
- Log activities to system journal
- Restart automatically on failures

#### Security Notes

- The secrets file is only readable by root (`600` permissions)
- API keys are never stored in the Nix configuration
- Consider using Cloudflare API tokens instead of Global API Key for better security
- The ddclient service runs as a dedicated user with minimal privileges
