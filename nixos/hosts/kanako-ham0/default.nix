{
  suites,
  profiles,
  mylib,
  ...
}:
{
  imports = [
    suites.server
    profiles.services.caddy
  ] ++ (mylib.path.scanPaths ./. "default.nix");

  system.stateVersion = "24.11";
}
