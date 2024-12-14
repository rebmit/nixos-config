{
  suites,
  profiles,
  mylib,
  ...
}:
{
  imports =
    suites.server
    ++ (with profiles; [
      services.caddy
      services.ntfy
      services.postgresql
    ])
    ++ (mylib.path.scanPaths ./. "default.nix");

  system.stateVersion = "24.11";
}
