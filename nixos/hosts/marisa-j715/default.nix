{
  suites,
  profiles,
  mylib,
  ...
}:
{
  imports = [
    suites.baseline
    suites.network
    suites.backup
    profiles.virtualization.rosetta
    profiles.users.rebmit
  ] ++ (mylib.path.scanPaths ./. "default.nix");

  home-manager.users.rebmit =
    { suites, profiles, ... }:
    {
      imports = [
        suites.workstation
        profiles.syncthing
      ];
    };

  system.stateVersion = "24.11";
}
