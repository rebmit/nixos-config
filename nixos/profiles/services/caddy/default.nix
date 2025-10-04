{
  config,
  pkgs,
  mylib,
  ...
}:
{
  services.caddy = {
    enable = true;
    enableReload = true;
    package = pkgs.caddy-rebmit;
    globalConfig = ''
      admin 127.0.0.1:${toString config.ports.caddy-admin}

      metrics {
        per_host
      }
    '';
  };

  systemd.services.caddy.serviceConfig = mylib.misc.serviceHardened // {
    AmbientCapabilities = [
      ""
      "CAP_NET_BIND_SERVICE"
    ];
    CapabilityBoundingSet = [
      ""
      "CAP_NET_BIND_SERVICE"
    ];
  };

  systemd.services.caddy-api.enable = false;

  preservation.directories = [
    config.services.caddy.dataDir
    config.services.caddy.logDir
  ];
}
