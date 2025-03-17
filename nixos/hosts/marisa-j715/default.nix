{
  suites,
  profiles,
  lib,
  mylib,
  ...
}:
{
  imports =
    suites.minimal
    ++ suites.network
    ++ [
      profiles.users.rebmit
    ]
    ++ (mylib.path.scanPaths ./. "default.nix");

  users.users.rebmit = {
    uid = lib.mkForce 501;
    isNormalUser = lib.mkForce false;
    isSystemUser = true;
    group = "users";
    createHome = true;
    home = "/home/rebmit";
    homeMode = "700";
    useDefaultShell = true;
  };

  system.stateVersion = "24.11";
}
