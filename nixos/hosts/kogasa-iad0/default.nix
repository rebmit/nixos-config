{
  suites,
  profiles,
  mylib,
  ...
}:
{
  imports = [
    suites.server
    profiles.services.caddy
    profiles.services.forgejo
    profiles.services.geofeed
    profiles.services.keycloak
    profiles.services.matrix.heisenbridge
    profiles.services.matrix.mautrix-telegram
    profiles.services.matrix.synapse
    profiles.services.miniflux
    profiles.services.postgresql
    profiles.services.well-known
  ]
  ++ (mylib.path.scanPaths ./. "default.nix");

  system.stateVersion = "24.11";
}
