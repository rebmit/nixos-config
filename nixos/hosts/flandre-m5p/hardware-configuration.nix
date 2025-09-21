{ profiles, ... }:
{
  imports = with profiles; [
    system.disko.luks-btrfs-common
  ];

  disko.devices = {
    nodev."/".mountOptions = [ "size=16G" ];
    disk.main = {
      device = "/dev/disk/by-path/pci-0000:04:00.0-nvme-1";
      content = {
        partitions.cryptroot.content = {
          settings = {
            keyFile = "/dev/disk/by-partuuid/3a2fec01-b092-4e0f-a20f-03dac6e08f30";
            keyFileSize = 512 * 64;
          };
        };
      };
    };
  };

  boot = {
    initrd.availableKernelModules = [
      "xhci_pci"
      "ahci"
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];
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
