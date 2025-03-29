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
      "uhci_hcd"
      "ehci_pci"
      "ahci"
      "virtio_pci"
      "virtio_scsi"
      "sr_mod"
      "virtio_blk"
    ];
  };
}
