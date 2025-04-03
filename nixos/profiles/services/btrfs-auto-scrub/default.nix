{ config, lib, ... }:
let
  inherit (lib.attrsets) attrValues;
  inherit (lib.lists) unique filter singleton;

  btrfsDevices = unique (
    map (fs: fs.device) (filter (fs: fs.fsType == "btrfs") (attrValues config.fileSystems))
  );
in
{
  services.btrfs.autoScrub = {
    enable = btrfsDevices != [ ];
    fileSystems = btrfsDevices;
  };

  preservation.preserveAt."/persist".directories = singleton {
    directory = "/var/lib/btrfs";
    mode = "0700";
    user = "root";
    group = "root";
  };
}
