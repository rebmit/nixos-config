{
  suites,
  mylib,
  ...
}:
{
  imports = suites.server ++ (mylib.path.scanPaths ./. "default.nix");

  services.caddy.enable = true;

  system.stateVersion = "24.05";
}
