# Installing NixOS from scratch

Written while setting up a UTM VM on an Apple Silicon MacBook, with the intent
that the same steps carry over to bare metal — specifically a **ThinkPad T14
Gen 6 Intel** (Core Ultra 7 258V, Lunar Lake). The steps below are the same on
both; only the marked details differ.

| | UTM VM (M2 MacBook) | ThinkPad T14 G6 |
| --- | --- | --- |
| ISO | minimal, **64-bit ARM** | minimal, **64-bit Intel/AMD** |
| Boot media | attach the ISO to the VM | `dd` the ISO to a USB stick |
| Disk | `/dev/vda` | `/dev/nvme0n1` (partitions `p1`, `p2`) |
| Network in installer | `enp0s1`, DHCP, just works | ethernet, or `nmcli` for Wi-Fi |
| Flake system | `aarch64-linux` | `x86_64-linux` |
| Disk encryption | skip | LUKS worth having on a laptop |

This is a condensed walkthrough, not a replacement for the official
[NixOS manual: installation](https://nixos.org/manual/nixos/stable/#sec-installation)
— consult its
[manual installation](https://nixos.org/manual/nixos/stable/#sec-installation-manual)
section for the partitioning, filesystem and bootloader details glossed over
below.

## 1. Get the ISO

Download the **minimal (non-graphical) ISO** for the right architecture from
<https://nixos.org/download.html>. Apple Silicon needs the ARM image; the
ThinkPad needs the Intel/AMD one.

**UTM:** *Create a New Virtual Machine* → **Virtualize** → **Linux**, select the
ISO, ~4 GB RAM, 4 CPUs, 25 GB drive. Default (Shared) networking hands out an
address on `192.168.64.0/24` that the Mac can reach.

**ThinkPad:** write the ISO to a USB stick, then in UEFI setup (F1 at boot)
disable **Secure Boot** — the NixOS installer is unsigned and will not boot
otherwise. If the NVMe drive is invisible to the installer, switch the storage
controller from Intel RST/VMD to AHCI/NVMe.

## 2. SSH into the installer

The installer boots as user `nixos` with no password. On the console:

```sh
passwd                    # throwaway password for the nixos user
sudo systemctl start sshd
ip -4 addr show           # note the address, e.g. 192.168.64.15
```

> [!NOTE]
>
> On the ThinkPad without ethernet, bring up Wi-Fi first. The minimal ISO ships
NetworkManager, so one command does it:
>
> ```sh
> sudo systemctl start NetworkManager   # if it is not already running
> nmcli device wifi list                # scan, confirm the SSID
> sudo nmcli device wifi connect "<SSID>" password "<password>"
> ```
> 
> `wpa_cli` is also present, but it is NetworkManager's backend here — driving
> it directly fights the running supplicant, and it needs an interactive
> `add_network` / `set_network` / `enable_network` dance. Use `nmcli`.

Then from the Mac:

```sh
ssh-copy-id -i ~/.ssh/id_ed25519.pub nixos@<ip>
ssh nixos@<ip>
```

If your keys live only in an agent (Proton Pass, 1Password) and not as files in
`~/.ssh/`, `ssh-copy-id` fails with `ERROR: No identities found`. Copy the
public key out of the agent's UI into a file, then point at it:

```sh
pbpaste > ~/.ssh/proton.pub && chmod 644 ~/.ssh/proton.pub
ssh-copy-id -f -i ~/.ssh/proton.pub nixos@<ip>   # -f: no private key on disk
```

Everything below is easier over SSH than in the console (copy/paste,
scrollback, agents).

> [!NOTE]
>
> The installer's host key and DHCP lease are ephemeral. After installing, the
> same IP answers with a different host key, so `ssh` refuses to connect — and
> it disables password authentication at the same time, which makes it look
> like a broken account rather than a key problem. Step 5 starts by clearing
> the entry.
>
> On a Mac, UTM's shared-network leases live in `/var/db/dhcpd_leases`, which
> maps hostname to IP without touching the VM console. On the installer
> console itself, use `ip -4 addr` — `ifconfig` is not in the minimal ISO.

## 3. Partition and format

> [!NOTE]
>
> See the manual's
[partitioning section](https://nixos.org/manual/nixos/stable/#sec-installation-manual-partitioning)
for the full story.

UEFI on both platforms, so an ESP plus a root partition. Substitute the disk
from the table above (`lsblk` to confirm). Both machines run this part:

```sh
DISK=/dev/vda           # ThinkPad: /dev/nvme0n1
ESP=512MB               # ThinkPad: 2GB

sudo parted $DISK -- mklabel gpt                  # wipe: new GPT partition table
sudo parted $DISK -- mkpart ESP fat32 1MB $ESP    # p1: boot partition
sudo parted $DISK -- set 1 esp on                 # mark p1 bootable to the firmware
sudo parted $DISK -- mkpart primary $ESP 100%     # p2: root, rest of the disk
```

The ESP holds every bootable generation's kernel and initrd, roughly 100MB
apiece. 512MB fits four or five, which is fine for a scratch VM that gets
`nix-collect-garbage -d` often. On the ThinkPad that would mean tripping over a
full `/boot` during ordinary work, and 2GB out of a 1TB disk costs nothing —
take the headroom, because growing the ESP later means moving the partition
that follows it.

> [!IMPORTANT]
>
> The paths diverge here. **VM:** carry on with "Format and mount" directly
> below. **ThinkPad:** stop and jump to
> [Encryption](#encryption-thinkpad) — p2 has to be encrypted *before* it is
> formatted, so running the next block first means starting over.

### Format and mount (VM)

```sh
sudo mkfs.fat -F 32 -n boot ${DISK}1     # ESP
sudo mkfs.ext4 -L nixos ${DISK}2         # root

sudo mount /dev/disk/by-label/nixos /mnt
sudo mkdir -p /mnt/boot
sudo mount /dev/disk/by-label/boot /mnt/boot
```

No swap partition: the VM does not want one, and elsewhere a swapfile declared
after install covers ordinary memory pressure without repartitioning.

```nix
swapDevices = [ { device = "/var/swapfile"; size = 32768; } ];
```

Hibernation is the one case that wants a real partition instead — see variant
B in the encryption section.

### Encryption (ThinkPad)

A work laptop holding proprietary material wants full-disk encryption, and it
has to be decided now — retrofitting LUKS means backing up and reinstalling.
Skip this in the VM.

This replaces "Format and mount" above: the partitioning is already done and
nothing has been formatted yet.

> [!IMPORTANT]
>
> Decide about hibernation before running anything here, because it changes how
> root is laid out. **No hibernation** (suspend-to-RAM only, the common case):
> take variant A, and add a swapfile after install — a file on an encrypted
> filesystem is encrypted for free, whereas a bare swap partition would need
> its own LUKS layer or it leaks memory contents in plaintext. **Hibernation:**
> take variant B, which puts root and swap in LVM inside the one LUKS
> container, so both are encrypted behind a single passphrase.

Both variants start the same way. The ESP (p1) stays plaintext; it has to, the
firmware reads it. Only p2 gets encrypted:

```sh
sudo mkfs.fat -F 32 -n boot ${DISK}p1               # ESP, unencrypted

sudo cryptsetup luksFormat --type luks2 ${DISK}p2   # prompts: type YES, then a passphrase
sudo cryptsetup open ${DISK}p2 cryptroot            # unlock as /dev/mapper/cryptroot
```

That passphrase is the only thing standing between a stolen laptop and the
data, and there is no recovery path — put it in your password manager now, from
a second device.

**Variant A — no hibernation:**

```sh
sudo mkfs.ext4 -L nixos /dev/mapper/cryptroot       # format the unlocked device
```

**Variant B — hibernation**, carving root and swap out of the container with
LVM:

```sh
sudo pvcreate /dev/mapper/cryptroot
sudo vgcreate vg /dev/mapper/cryptroot
sudo lvcreate -L 32G -n swap vg          # sized to RAM
sudo lvcreate -l 100%FREE -n root vg

sudo mkfs.ext4 -L nixos /dev/vg/root
sudo mkswap -L swap /dev/vg/swap
sudo swapon /dev/vg/swap                 # so nixos-generate-config sees it
```

Variant B also needs `boot.resumeDevice = "/dev/vg/swap";` in the host config.

Then mount, identically either way — both label root `nixos`:

```sh
sudo mount /dev/disk/by-label/nixos /mnt
sudo mkdir -p /mnt/boot
sudo mount /dev/disk/by-label/boot /mnt/boot
```

`nixos-generate-config` in step 4 detects the open mapper device (and the LVM
volumes, for B) and emits the matching `boot.initrd.luks.devices` entry. Check
that it did before rebooting, or the installed system will not unlock:

```sh
grep -A2 luks /mnt/etc/nixos/hardware-configuration.nix
```

Two limits worth knowing. The kernel and initrd sit unencrypted on the ESP, so
this protects data at rest, not against someone tampering with the boot chain —
[lanzaboote](https://github.com/nix-community/lanzaboote) adds Secure Boot
signing on top if you care. And unlocking is a passphrase at every boot; TPM2
auto-unlock via `systemd-cryptenroll` is possible but weakens the threat model
it was bought for.

## 4. Install

> [!NOTE]
>
> Everything written to `/mnt/etc/nixos/configuration.nix` in this step is
> throwaway. Step 5 hands the system over to this flake, and from then on
> `nix/hosts/<hostname>/` defines it — this file only has to get the machine
> booted and reachable over SSH once. Keep it minimal; permanent settings
> belong in the flake.
>
> The exception is `hardware-configuration.nix`, which is generated from the
> actual disks and gets copied into the repo in step 5.

```sh
sudo nixos-generate-config --root /mnt
```

Before installing, edit the configuration with
`sudo vim /mnt/etc/nixos/configuration.nix` so the machine is reachable over SSH
on first boot — otherwise you are back on the console. The file is root-owned,
so open it with `sudo -e` (or `sudo vim`); a plain `vim` reads it fine and then
fails with `E212` on write:

```nix
networking.hostName = "<hostname>";   # match a directory in nix/hosts/
services.openssh.enable = true;
users.users.<username> = {
  isNormalUser = true;
  extraGroups = [ "wheel" ];       # sudo
  initialPassword = "changeme";    # see below
  openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAA... you@mac" ];
};
```

`isNormalUser` on its own creates the account with a locked password, and
`wheel` membership still asks for one — so without `initialPassword` you can
SSH in on your key and then find `sudo` unusable, which blocks the rebuild in
step 5. It applies only at account creation, so a later `passwd` sticks. The
alternatives are setting the password from the console as root after first
boot, or `security.sudo.wheelNeedsPassword = false;` — reasonable on a scratch
VM, less so on a laptop.

`nixos-generate-config` mounts `/boot` with `fmask=0022` `dmask=0022`, which
leaves the ESP world-readable — `bootctl` warns about it during install, since
the systemd-boot random seed lives there. Harmless in the VM. On the ThinkPad,
tighten it before installing by changing the two masks on the `options` line
that `/mnt/etc/nixos/hardware-configuration.nix` already contains:

```nix
fileSystems."/boot" =
  { device = "/dev/disk/by-uuid/XXXX-XXXX";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];   # generated as 0022
  };
```

Yes, that file says not to modify it — but step 5 copies it into the repo, so
the edit persists, and it is the only definition of the option. Adding it to
`configuration.nix` instead would merge the two lists rather than replace them,
and need `lib.mkForce` to win.

Booting UEFI, `nixos-generate-config` already emits
`boot.loader.systemd-boot.enable` and `boot.loader.efi.canTouchEfiVariables`
uncommented — confirm they are there rather than adding them.

Then:

```sh
sudo nixos-install     # prompts for the root password
sudo reboot
```

Detach the install media first: eject the ISO in UTM (or move the disk up the
boot order); pull the USB stick on the ThinkPad.

## 5. Take over with this flake

Re-connect after reboot:

```sh
grep -B2 '<hostname>' /var/db/dhcpd_leases   # VM: the lease now shows the new hostname
ssh-keygen -R <ip>                           # host key changed at reboot, the IP usually did not
ssh <username>@<ip>
```

Clone the repo and copy the generated hardware config into it.
`hardware-configuration.nix` must be generated on the machine it describes — it
pins the filesystems by UUID, so it can never be copied from another host:

```sh
nix-shell -p git --run 'git clone https://github.com/fredrikaverpil/dotfiles.git ~/.dotfiles'

mkdir -p ~/.dotfiles/nix/hosts/<hostname>
sudo cp /etc/nixos/hardware-configuration.nix ~/.dotfiles/nix/hosts/<hostname>/hardware-configuration.nix
```

The host also needs `configuration.nix` and `users/<username>.nix` in that
directory, plus a `nixosConfigurations.<hostname> = lib.mkNixos { ... }` entry
in `flake.nix`. If they are not there yet, copy `nix/hosts/wily-vm/` and change
the hostname and `nixpkgs.hostPlatform`.

**ThinkPad extras** (not needed in the VM). Lunar Lake needs the
redistributable firmware blobs for its Intel Wi-Fi and Xe2 graphics:

```nix
hardware.enableRedistributableFirmware = true;
boot.loader.systemd-boot.configurationLimit = 20;   # 2GB ESP fits ~20
```

Neither the kernel nor the nixpkgs channel needs attention. `mkNixos` builds
every host from `nixpkgs-unstable`, whose default kernel is 6.18, while Xe2
was enabled by default in 6.12 (experimental in 6.11) — comfortably covered.
Do not reach for `boot.kernelPackages = pkgs.linuxPackages_latest`
reflexively: it trades the LTS for more rebuilds, thinner cache coverage, and
conflicts with any nixos-hardware module that sets the kernel itself. Reach
for it only if something is actually broken.

Check [nixos-hardware](https://github.com/NixOS/nixos-hardware) for a matching
ThinkPad module, and fall back to its `common-cpu-intel` /
`common-pc-laptop-ssd` profiles if there is no T14 G6 entry yet.

Then build before switching, so a bad eval fails harmlessly. Run **both** as
root on the first pass — see the note below:

```sh
git -C ~/.dotfiles add nix/hosts/<hostname>   # flakes only see git-tracked paths
sudo nixos-rebuild build --flake ~/.dotfiles#<hostname>
sudo nixos-rebuild switch --flake ~/.dotfiles#<hostname>
```

`build` is normally unprivileged, but on the first run it must not be.
`nix/shared/system/linux.nix` puts you in `trusted-users`, and that setting
only exists once this very switch has landed — until then nix reports:

```
warning: ignoring untrusted substituter 'https://cache.numtide.com',
you are not a trusted user
```

and the LLM agent CLIs compile from source instead of downloading. No flag
works around it: untrusted users cannot set substituters by any mechanism, so
`--option extra-substituters` does not help either. Root is always trusted.
From the second rebuild onward, plain `nixos-rebuild build` honors the caches.

The Pi cache (`nixos-raspberrypi.cachix.org`) is offered on every host because
`nixConfig` in `flake.nix` is flake-wide rather than per-host. Nothing outside
`rpi5-homelab` fetches from it; the prompt is noise.

## 6. Verify the takeover

The switch replaced userspace but you are still running the kernel and boot
entry from step 4, so nothing has proven the flake can actually boot the
machine yet. Check the switch first, without closing your session:

```sh
git -C ~/.dotfiles status                 # stow --adopt absorbed nothing?
ls -la ~/.zshrc ~/.gitconfig              # symlinks into ~/.dotfiles/stow/
```

`stow --adopt` runs during home-manager activation and silently pulls any real
file sitting where a managed symlink belongs *into the repo*, so a dirty `git
status` here means a config file was overwritten, not that something failed.

Then open a **second** SSH session from the other machine before closing this
one. If the host config lost `services.openssh.enable` or your key, this is
where you find out while still holding a working shell.

Now reboot. This is the step that proves `boot.loader.systemd-boot.enable`
survived the handover — the failure this whole VM rehearsal exists to catch
before it happens on the ThinkPad:

```sh
sudo reboot
```

The boot menu should now offer two generations: the `nixos-install` one from
step 4 and the flake's, with the flake's selected by default. Once back up:

```sh
hostname                                          # matches networking.hostName
readlink /run/current-system                      # the store path build printed
nix config show | grep trusted-users              # now lists your user
nixos-rebuild build --flake ~/.dotfiles#<hostname>   # no sudo, no cache warnings
```

That last one closes the loop: if it runs clean, `trusted-users` took effect
and ordinary unprivileged builds work from here on.

Only once all of that passes, remove the non-flake fallback:

> [!WARNING]
>
> `/etc/nixos/configuration.nix` is now dead — the flake defines the machine —
> but a bare `sudo nixos-rebuild switch` with no `--flake` still falls back to
> it and would silently rebuild the machine from the throwaway step 4 config.
> Move it aside so that fails loudly instead:
>
> ```sh
> sudo mv /etc/nixos/configuration.nix /etc/nixos/configuration.nix.superseded
> ```
>
> Leave `/etc/nixos/hardware-configuration.nix` alone — nothing reads it once
> its importer is gone. To refresh the repo copy after a disk change, print a
> fresh one rather than regenerating in place. A plain `nixos-generate-config`
> logs `writing /etc/nixos/configuration.nix...` and brings the file you just
> moved aside back, restoring the trap:
>
> ```sh
> sudo nixos-generate-config --show-hardware-config \
>   | nix run u#nixfmt -- - \
>   | diff - ~/.dotfiles/nix/hosts/<hostname>/hardware-configuration.nix
> ```
