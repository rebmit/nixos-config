{ profiles, ... }:
{
  imports = with profiles; [
    system.disko.btrfs-common
  ];

  disko.devices = {
    nodev."/".mountOptions = [ "size=6G" ];
    disk.main.device = "/dev/vda";
  };

  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };
    initrd.availableKernelModules = [ "xhci_pci" ];
  };
}
