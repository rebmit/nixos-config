{ profiles, ... }:
{
  imports = with profiles; [
    system.disko.luks-btrfs-common
  ];

  disko.devices = {
    nodev."/".mountOptions = [ "size=16G" ];
    disk.main.device = "/dev/disk/by-path/pci-0000:04:00.0-nvme-1";
  };

  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
      # workaround for https://github.com/nix-community/disko/issues/678
      luks.devices.cryptroot = {
        keyFile = "/dev/disk/by-id/usb-aigo_U330_80101016-0:0";
        keyFileSize = 512 * 64;
      };
    };
    kernelModules = [ "kvm-amd" ];
    loader = {
      efi.canTouchEfiVariables = false;
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
