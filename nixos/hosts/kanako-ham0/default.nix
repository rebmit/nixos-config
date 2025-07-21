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
    profiles.services.ntfy
    profiles.services.vaultwarden
  ]
  ++ (mylib.path.scanPaths ./. "default.nix");

  system.stateVersion = "24.11";
}
