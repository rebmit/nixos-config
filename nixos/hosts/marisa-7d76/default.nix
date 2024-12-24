{
  suites,
  profiles,
  mylib,
  ...
}:
{
  imports =
    suites.workstation
    ++ [
      profiles.programs.adb
      profiles.system.boot.binfmt
      profiles.system.boot.secure-boot
      profiles.users.rebmit
    ]
    ++ (mylib.path.scanPaths ./. "default.nix");

  home-manager.users.rebmit =
    { suites, profiles, ... }:
    {
      imports = suites.desktop-workstation ++ [
        profiles.syncthing
      ];

      programs.niri.settings = {
        input.tablet.map-to-output = "HDMI-A-1";
        outputs."HDMI-A-1".scale = 1.75;
      };
    };

  system.stateVersion = "24.11";
}
