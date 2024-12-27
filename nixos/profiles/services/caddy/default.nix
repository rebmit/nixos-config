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
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/mholt/caddy-l4@3c6cc2c0ee0875899fde271fbdef95be3fef7a92" ];
      hash = "sha256-s5LzVOAvVsZxbhdgIdpe1OBSHIAc/tCi+1pEofeQx6k=";
    };
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
    admin 127.0.0.1:${toString config.networking.ports.caddy-admin}

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

  services.restic.backups.b2.paths = [
    "/persist${config.services.caddy.dataDir}"
  ];
}
