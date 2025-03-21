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
      services.forgejo
      services.forgejo-actions-runner
      services.geofeed
      services.keycloak
      services.matrix.heisenbridge
      services.matrix.mautrix-telegram
      services.matrix.synapse
      services.miniflux
      services.postgresql
      services.well-known
      virtualization.podman
    ])
    ++ (mylib.path.scanPaths ./. "default.nix");

  system.stateVersion = "24.11";
}
