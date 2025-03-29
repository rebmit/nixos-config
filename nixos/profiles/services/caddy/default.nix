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

  services.caddy.globalConfig = ''
    admin 127.0.0.1:${toString config.ports.caddy-admin}

    servers {
      metrics
    }
  '';

  preservation.preserveAt."/persist".directories = [
    {
      directory = config.services.caddy.dataDir;
      mode = "-";
      user = "-";
      group = "-";
    }
    {
      directory = config.services.caddy.logDir;
      mode = "-";
      user = "-";
      group = "-";
    }
  ];
}
