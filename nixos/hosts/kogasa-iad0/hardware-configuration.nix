{ modulesPath, profiles, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    profiles.system.disko.btrfs-bios-compat
  ];

  disko.devices = {
    nodev."/".mountOptions = [ "size=2G" ];
    disk.main.device = "/dev/vda";
  };

  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "virtio_pci"
    "sr_mod"
    "virtio_blk"
  ];
}
