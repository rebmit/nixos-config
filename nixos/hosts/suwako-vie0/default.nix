{
  suites,
  mylib,
  ...
}:
{
  imports = suites.server ++ (mylib.path.scanPaths ./. "default.nix");

  system.stateVersion = "24.05";
}
