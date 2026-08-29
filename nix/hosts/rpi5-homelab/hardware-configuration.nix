{nixos-raspberrypi, ...}: {
  # Hardware-specific configuration for Raspberry Pi 5
  # This file defines the hardware capabilities and storage layout

  # Import Raspberry Pi 5 hardware modules from nixos-raspberrypi
  imports = with nixos-raspberrypi.nixosModules; [
    raspberry-pi-5.base # Core Pi 5 hardware support (CPU, memory, GPIO)
    raspberry-pi-5.display-vc4 # VideoCore IV GPU support for hardware acceleration
    raspberry-pi-5.bluetooth # Bluetooth hardware support
  ];

  # Disko configuration for declarative disk partitioning
  # This automatically partitions and formats the storage device during installation
  # Using disko ensures reproducible storage layouts across deployments
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1"; # NVMe SSD connected via PCIe (faster than SD card)
        content = {
          type = "gpt"; # GPT partition table for modern UEFI boot
          partitions = {
            # Firmware partition for Raspberry Pi bootloader and kernel
            firmware = {
              size = "512M"; # Sufficient space for firmware and multiple kernels
              type = "EF00"; # EFI System Partition type
              content = {
                type = "filesystem";
                format = "vfat"; # FAT32 required by Raspberry Pi firmware
                mountpoint = "/boot/firmware";
              };
            };
            # Root filesystem partition
            root = {
              size = "100%"; # Use remaining disk space
              content = {
                type = "filesystem";
                format = "ext4"; # Reliable filesystem with good Pi support
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };

  # Add persistent mount for homelab data drive
  fileSystems."/mnt/homelab-data" = {
    device = "/dev/disk/by-label/homelab-data";
    fsType = "ext4";
    options = ["defaults" "nofail"];
  };
}

