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

### First-Time Installation Actions

After the initial NixOS installation, you need to set up SOPS secrets management
for services like ddclient to work properly.

#### 1. Convert SSH key to age format on development machine

Generate a SSH key unless you already have one you want copied over:

```sh
# Generate new SSH key pair on Pi
ssh-keygen -t ed25519 -C "fredrik@rpi5-homelab"

# Get the public key and update step 1 with this key instead
cat ~/.ssh/id_ed25519.pub

# OR - on development machine, copy your SSH private key to the Pi
scp ~/.ssh/id_ed25519 fredrik@<pi-ip>:~/.ssh/id_ed25519
scp ~/.ssh/id_ed25519.pub fredrik@<pi-ip>:~/.ssh/id_ed25519.pub

# On Pi, secure the key files
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

The SOPS configuration uses SSH keys converted to age format. On your
development machine, convert your SSH public key:

```sh
# Install ssh-to-age if not available
nix-shell -p ssh-to-age

# Convert your SSH public key to age format
ssh-to-age < ~/.ssh/id_ed25519.pub
```

Copy the age public key output (the `age1...` string).

#### 2. Update SOPS configuration on development machine

Edit `nix/hosts/rpi5-homelab/secrets/.sops.yaml` and replace the placeholder
with your converted age public key:

```yaml
keys:
  - &fredrik_ssh age1your_converted_ssh_key_from_step_1
creation_rules:
  - path_regex: secrets\.yaml$
    key_groups:
      - age:
          - *fredrik_ssh
```

Deploy this to the rpi5.

#### 3. Set up SSH key and age key file on Pi

SSH into the Pi. You need the SSH private key that corresponds to the public key
used in step 1.

**Then convert SSH private key to age format:**

```sh
# Create the directory structure
mkdir -p ~/.config/sops/age

# Convert SSH private key to age format and save it
nix-shell -p ssh-to-age --run "ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt"

# Secure the key file
chmod 600 ~/.config/sops/age/keys.txt
```

#### 4. Encrypt secrets with actual values

Edit `nix/hosts/rpi5-homelab/secrets/secrets.yaml` and replace placeholders with
real values, then encrypt:

```sh
cd nix/hosts/rpi5-homelab/secrets/
nix-shell -p sops --run "sops -e -i secrets.yaml"
```

#### 5. Redeploy to Pi

From your development machine, redeploy the configuration:

```sh
nixos-anywhere --flake .#rpi5-homelab --build-on remote --phases install root@<pi-ip>
```

Or if you prefer to build locally:

```sh
nixos-anywhere --flake .#rpi5-homelab <pi-ip>
```

#### 6. Verify services are running

SSH back into the Pi and verify:

```sh
# Check that secrets are decrypted
ls -la /run/secrets/

# Check ddclient service status
systemctl status ddclient

# View ddclient logs if needed
journalctl -u ddclient -f
```
