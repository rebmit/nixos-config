{
  suites,
  profiles,
  mylib,
  ...
}:
{
  imports = [
    suites.server
    profiles.services.knot.ddns
  ]
  ++ (mylib.path.scanPaths ./. "default.nix");

  system.stateVersion = "24.11";
}
