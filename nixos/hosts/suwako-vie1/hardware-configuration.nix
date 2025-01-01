{ modulesPath, profiles, ... }:
{
  imports = with profiles; [
    (modulesPath + "/profiles/qemu-guest.nix")
    system.disko.btrfs-bios-compat
  ];

  disko.devices = {
    nodev."/".mountOptions = [ "size=1G" ];
    disk.main.device = "/dev/sda";
  };

  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "virtio_pci"
    "virtio_scsi"
    "sd_mod"
    "sr_mod"
  ];
}
