{ modulesPath, profiles, ... }:
{
  imports = with profiles; [
    (modulesPath + "/profiles/qemu-guest.nix")
    system.disko.btrfs-bios-compat
  ];

  disko.devices = {
    nodev."/".mountOptions = [ "size=2G" ];
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
