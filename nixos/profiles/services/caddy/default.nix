{ config, mylib, ... }:
{
  services.caddy = {
    enable = true;
    enableReload = true;
  };

  systemd.services.caddy.serviceConfig = mylib.misc.serviceHardened // {
    AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
    CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
  };

  systemd.services.caddy-api.serviceConfig = mylib.misc.serviceHardened // {
    AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
    CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
  };

  services.restic.backups.b2.paths = [ config.services.caddy.dataDir ];
}
