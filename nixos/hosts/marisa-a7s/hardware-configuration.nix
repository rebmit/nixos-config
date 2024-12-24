{ profiles, lib, ... }:
{
  imports = with profiles; [
    system.disko.luks-btrfs-common
  ];

  disko.devices = {
    nodev."/".mountOptions = [ "size=8G" ];
    disk.main.device = "/dev/disk/by-path/pci-0000:04:00.0-nvme-1";
  };

  boot = {
    initrd.availableKernelModules = [
      "nvme"
      "ahci"
      "xhci_pci"
    ];
    kernelModules = [ "kvm-amd" ];
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = lib.mkDefault true;
    };
  };

  networking.wireless.iwd.enable = true;

  hardware = {
    amdgpu.initrd.enable = true;
    cpu.amd.updateMicrocode = true;
    enableRedistributableFirmware = true;
    graphics.enable = true;
  };

  services = {
    udev.extraHwdb = ''
      evdev:input:b*v046Dp4089*
        KEYBOARD_KEY_70039=esc
        KEYBOARD_KEY_70029=capslock

      evdev:atkbd:dmi:*
        KEYBOARD_KEY_3a=esc
        KEYBOARD_KEY_01=capslock
    '';
  };
}
