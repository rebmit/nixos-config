{
  suites,
  profiles,
  mylib,
  ...
}:
{
  imports = [
    suites.server
    profiles.services.bgp
    profiles.services.caddy
    profiles.services.knot.secondary
  ] ++ (mylib.path.scanPaths ./. "default.nix");

  system.stateVersion = "24.11";
}
