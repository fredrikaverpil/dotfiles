# Installing NixOS from scratch

The graphical installer sets up Wi-Fi, disk encryption, partitions and the
user. This flake then takes the machine over, over SSH from another machine.
See the [NixOS manual](https://nixos.org/manual/nixos/stable/#sec-installation)
for anything glossed over below.

## 1. Boot the installer

Download the **graphical ISO** for the machine's architecture from
<https://nixos.org/download/> and write it to a USB stick.

In UEFI setup (F1 at boot on a ThinkPad), disable **Secure Boot**: the NixOS
installer is unsigned and will not boot otherwise. If the NVMe drive is
invisible to the installer, switch the storage controller from Intel RST/VMD to
AHCI/NVMe.

## 2. Run the installer

Connect to Wi-Fi from the live desktop, then start the installer:

- **Users**: the computer name is the host's directory in `nix/hosts/`
  (existing, or added in step 4), and the username its `users/<username>.nix`.
  The flake keeps the password set here.
- **Desktop**: _No desktop_. The flake brings its own.
- **Partitions**: _Erase disk_, _Encrypt system_ and a swap option.

The LUKS passphrase is the only thing standing between a stolen laptop and the
data, and there is no recovery path: put it in your password manager now, from
a second device. It protects data at rest, not the boot chain: the kernel and
initrd sit unencrypted on the ESP.
[lanzaboote](https://github.com/nix-community/lanzaboote) adds Secure Boot
signing on top.

Reboot into the installed system and pull the USB stick.

## 3. SSH in

The installed system has no SSH server yet. On its console, add
`services.openssh.enable = true;` to `/etc/nixos/configuration.nix`, which
stays the live config until the flake takes over:

```sh
sudo nano /etc/nixos/configuration.nix
sudo nixos-rebuild switch
ip -4 addr   # note the address
```

If it is offline, `nmcli device wifi connect "<SSID>" password "<password>"`.

Then from the other machine:

```sh
ssh-copy-id -o IdentitiesOnly=yes -i ~/.ssh/id_ed25519.pub <username>@<ip>
ssh <username>@<ip>
```

If your keys live only in an agent (Proton Pass, 1Password) and not as files in
`~/.ssh/`, `ssh-copy-id` fails with `ERROR: No identities found`. Copy the
public key out of the agent's UI into a file, then point at it:

```sh
pbpaste > ~/.ssh/proton.pub && chmod 644 ~/.ssh/proton.pub
ssh-copy-id -f -i ~/.ssh/proton.pub <username>@<ip>   # -f: no private key on disk
```

## 4. Take over with this flake

Clone the repo and copy the generated hardware config into it.
`hardware-configuration.nix` must be generated on the machine it describes: it
pins the filesystems by UUID, so it can never be copied from another host.

```sh
nix-shell -p git --run 'git clone https://github.com/fredrikaverpil/dotfiles.git ~/.dotfiles'

mkdir -p ~/.dotfiles/nix/hosts/<hostname>
sudo cp /etc/nixos/hardware-configuration.nix ~/.dotfiles/nix/hosts/<hostname>/hardware-configuration.nix
```

The host also needs `configuration.nix` and `users/<username>.nix` in that
directory, plus a `nixosConfigurations.<hostname> = lib.mkNixos { ... }` entry
in `flake.nix`. If they are not there yet, copy `nix/hosts/renoir/` and change
the hostname and `nixpkgs.hostPlatform`.

Carry two things over from the installer's config:

- **Encrypted swap**: the installer writes the swap partition's
  `boot.initrd.luks.devices` entry to `/etc/nixos/configuration.nix`, not
  `hardware-configuration.nix`. Copy it into the host's `configuration.nix`,
  or the swap device never unlocks:

  ```sh
  grep -A1 luks /etc/nixos/configuration.nix
  ```

- **ESP permissions**: `fileSystems."/boot"` is generated with `fmask=0022`
  `dmask=0022`, which leaves the ESP world-readable; `bootctl` warns about it,
  since the systemd-boot random seed lives there. Change both to `0077` in the
  repo's `hardware-configuration.nix`.

Intel Lunar Lake also needs `hardware.enableRedistributableFirmware = true;`
for its Wi-Fi and Xe2 graphics (see `nix/hosts/wily/`). Check
[nixos-hardware](https://github.com/NixOS/nixos-hardware) for a module matching
the machine.

Then build before switching, so a bad eval fails harmlessly. Run **both** as
root on the first pass:

```sh
git -C ~/.dotfiles add nix/hosts/<hostname>   # flakes only see git-tracked paths
sudo nixos-rebuild build --flake ~/.dotfiles#<hostname>
sudo nixos-rebuild switch --flake ~/.dotfiles#<hostname>
```

`nix/shared/system/linux.nix` puts you in `trusted-users`, which only exists
once this switch has landed. Until then nix reports
`warning: ignoring untrusted substituter 'https://cache.numtide.com'`, and the
LLM agent CLIs compile from source instead of downloading. Root is always
trusted. The Pi cache (`nixos-raspberrypi.cachix.org`) is offered on every host
because `nixConfig` in `flake.nix` is flake-wide; only `rpi5-homelab` fetches
from it.

## 5. Verify the takeover

The switch replaced userspace, but you are still running the installer's
kernel and boot entry. Check the switch first, without closing your session:

```sh
git -C ~/.dotfiles status                 # stow --adopt absorbed nothing?
ls -la ~/.zshrc ~/.gitconfig              # symlinks into ~/.dotfiles/stow/
```

`stow --adopt` runs during home-manager activation and silently pulls any real
file sitting where a managed symlink belongs _into the repo_, so a dirty
`git status` here means a config file was overwritten, not that something
failed.

Then open a **second** SSH session before closing this one. If the host config
lost `services.openssh.enable` or your key, this is where you find out while
still holding a working shell.

Now reboot, which proves the flake can boot the machine. The boot menu should
default to the flake's generation, above the installer's. Once back up:

```sh
hostname                                             # matches networking.hostName
readlink /run/current-system                         # the store path build printed
nix config show | grep trusted-users                 # now lists your user
nixos-rebuild build --flake ~/.dotfiles#<hostname>   # no sudo, no cache warnings
```

Only once all of that passes, remove the non-flake fallback:

> [!WARNING]
>
> `/etc/nixos/configuration.nix` is now dead, since the flake defines the
> machine, but a bare `sudo nixos-rebuild switch` with no `--flake` still falls
> back to it and would silently rebuild the machine from the installer's
> config. Move it aside so that fails loudly instead:
>
> ```sh
> sudo mv /etc/nixos/configuration.nix /etc/nixos/configuration.nix.superseded
> ```
>
> Leave `/etc/nixos/hardware-configuration.nix` alone; nothing reads it once its
> importer is gone. To refresh the repo copy after a disk change, print a fresh
> one rather than regenerating in place. A plain `nixos-generate-config` brings
> the file you just moved aside back, restoring the trap:
>
> ```sh
> sudo nixos-generate-config --show-hardware-config \
>   | nix run u#nixfmt -- - \
>   | diff - ~/.dotfiles/nix/hosts/<hostname>/hardware-configuration.nix
> ```
