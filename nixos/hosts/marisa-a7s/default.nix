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
        outputs."eDP-1".scale = 1.2;
      };
    };

  services.power-profiles-daemon.enable = true;

  system.stateVersion = "24.11";
}
