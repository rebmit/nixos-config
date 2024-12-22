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
      services.prometheus.ping-exporter
    ])
    ++ (mylib.path.scanPaths ./. "default.nix");

  system.stateVersion = "24.05";
}
