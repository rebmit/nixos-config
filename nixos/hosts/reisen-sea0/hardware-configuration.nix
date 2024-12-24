{ modulesPath, profiles, ... }:
{
  imports = with profiles; [
    (modulesPath + "/profiles/qemu-guest.nix")
    system.disko.btrfs-common
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
      "ahci"
      "xhci_pci"
      "virtio_pci"
      "sr_mod"
      "virtio_blk"
    ];
  };
}
