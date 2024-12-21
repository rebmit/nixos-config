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
      services.prometheus.node-exporter
    ])
    ++ (mylib.path.scanPaths ./. "default.nix");

  system.stateVersion = "24.11";
}
