{
  suites,
  profiles,
  mylib,
  ...
}:
{
  imports =
    suites.server
    ++ [
      profiles.virtualization.libvirtd
    ]
    ++ (mylib.path.scanPaths ./. "default.nix");

  system.stateVersion = "24.05";
}
