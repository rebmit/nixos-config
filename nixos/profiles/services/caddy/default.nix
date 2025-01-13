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
      plugins = [ "github.com/mholt/caddy-l4@v0.0.0-20250102174933-6e5f5e311ead" ];
      hash = "sha256-dTi+xq0yINYvV07dO+adde4vz+z2oc4nybt5DoWD7k0=";
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
