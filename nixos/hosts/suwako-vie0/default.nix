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
      services.keycloak
      services.knot.secondary
      services.matrix-synapse
      services.miniflux
      services.ntfy
      services.postgresql
      services.well-known
    ])
    ++ (mylib.path.scanPaths ./. "default.nix");

  system.stateVersion = "24.11";
}
