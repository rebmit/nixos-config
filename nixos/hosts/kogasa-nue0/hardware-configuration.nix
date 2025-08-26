{ modulesPath, profiles, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    profiles.system.disko.btrfs-common
  ];

  disko.devices = {
    nodev."/".mountOptions = [ "size=1G" ];
    disk.main.device = "/dev/vda";
  };

  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };
    initrd.availableKernelModules = [
      "ata_piix"
      "uhci_hcd"
      "virtio_pci"
      "sr_mod"
      "virtio_blk"
    ];
  };
}
