{ profiles, ... }:
{
  imports = with profiles; [
    system.disko.luks-btrfs-common
  ];

  disko.devices = {
    nodev."/".mountOptions = [ "size=4G" ];
    disk.main.device = "/dev/disk/by-path/pci-0000:01:00.0-nvme-1";
  };

  boot = {
    initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "thunderbolt"
      "uas"
      "sd_mod"
    ];
    kernelModules = [ "kvm-amd" ];
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };
  };

  networking.wireless.iwd.enable = true;

  hardware = {
    amdgpu.initrd.enable = true;
    cpu.amd.updateMicrocode = true;
    enableRedistributableFirmware = true;
    graphics.enable = true;
  };
}
