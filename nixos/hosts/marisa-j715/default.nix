{
  suites,
  profiles,
  mylib,
  ...
}:
{
  imports =
    suites.baseline
    ++ suites.network
    ++ (with profiles; [
      virtualization.rosetta
      users.rebmit
    ])
    ++ (mylib.path.scanPaths ./. "default.nix");

  home-manager.users.rebmit =
    { suites, profiles, ... }:
    {
      imports = suites.workstation ++ [
        profiles.syncthing
      ];
    };

  system.stateVersion = "24.11";
}
