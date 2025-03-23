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
      profiles.virtualization.qemu-user-static
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
        outputs = {
          "HDMI-A-1" = {
            scale = 1.75;
          };
          "DP-1" = {
            scale = 1.75;
            position = {
              x = 0;
              y = 0;
            };
          };
        };
      };
    };

  system.stateVersion = "24.11";
}
