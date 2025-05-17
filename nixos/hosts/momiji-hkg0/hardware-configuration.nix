{ modulesPath, profiles, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    profiles.system.disko.btrfs-bios-compat
  ];

  disko.devices = {
    nodev."/".mountOptions = [ "size=1G" ];
    disk.main.device = "/dev/vda";
  };

  boot.initrd.availableKernelModules = [
    "ahci"
    "xhci_pci"
    "virtio_pci"
    "sr_mod"
    "virtio_blk"
  ];
}
