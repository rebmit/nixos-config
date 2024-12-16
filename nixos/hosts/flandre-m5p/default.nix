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
      services.knot.ddns
      virtualization.libvirtd
    ])
    ++ (mylib.path.scanPaths ./. "default.nix");

  system.stateVersion = "24.05";
}
