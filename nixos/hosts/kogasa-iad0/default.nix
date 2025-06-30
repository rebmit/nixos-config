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
    profiles.services.geofeed
    profiles.services.well-known
  ] ++ (mylib.path.scanPaths ./. "default.nix");

  system.stateVersion = "24.11";
}
