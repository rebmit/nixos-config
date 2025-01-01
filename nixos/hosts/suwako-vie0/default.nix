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
      services.matrix.heisenbridge
      services.matrix.mautrix-telegram
      services.matrix.synapse
      services.miniflux
      services.postgresql
      services.well-known
    ])
    ++ (mylib.path.scanPaths ./. "default.nix");

  system.stateVersion = "24.11";
}
