{
  suites,
  lib,
  mylib,
  flake,
  ...
}:
{
  imports = [
    suites.baseline
    suites.network
    suites.backup
    flake.flake.modules.nixos."users/rebmit"
  ]
  ++ (mylib.path.scanPaths ./. "default.nix");

  home-manager.users.rebmit =
    { suites, profiles, ... }:
    {
      imports = [
        suites.workstation
        profiles.syncthing
      ];

      programs.git = {
        signing.key = lib.mkForce "~/.ssh/id_ed25519_sk_rk.pub";
      };
    };

  system.stateVersion = "24.11";
}
