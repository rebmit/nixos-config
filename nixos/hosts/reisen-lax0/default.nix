{
  suites,
  mylib,
  ...
}:
{
  imports = suites.server ++ (mylib.path.scanPaths ./. "default.nix");

  services.caddy.enable = false;

  system.stateVersion = "24.05";
}
