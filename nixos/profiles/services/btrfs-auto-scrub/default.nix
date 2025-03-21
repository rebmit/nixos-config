{ config, lib, ... }:
let
  btrfsDevices = lib.unique (
    lib.mapAttrsToList (_name: value: value.device) (
      lib.filterAttrs (_name: value: value.fsType == "btrfs") config.fileSystems
    )
  );
in
{
  services.btrfs.autoScrub = {
    enable = btrfsDevices != [ ];
    fileSystems = btrfsDevices;
  };

  preservation.preserveAt."/persist".directories = [
    {
      directory = "/var/lib/btrfs";
      mode = "0700";
      user = "root";
      group = "root";
    }
  ];
}
