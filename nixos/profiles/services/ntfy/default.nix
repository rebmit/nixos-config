{
  config,
  lib,
  mylib,
  ...
}:
{
  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "https://push.rebmit.moe";
      listen-http = "127.0.0.1:${toString config.networking.ports.ntfy}";
      auth-default-access = "deny-all";
      behind-proxy = true;
    };
  };

  systemd.services.ntfy-sh.serviceConfig = mylib.misc.serviceHardened // {
    AmbientCapabilities = lib.mkForce [ "" ];
    CapabilityBoundingSet = lib.mkForce [ "" ];
    DynamicUser = lib.mkForce false;
  };

  services.caddy.virtualHosts."push.rebmit.moe" = {
    serverAliases = [ "push.rebmit.workers.moe" ];
    extraConfig = ''
      reverse_proxy ${config.services.ntfy-sh.settings.listen-http}
    '';
  };

  preservation.preserveAt."/persist".directories = [
    {
      directory = "/var/lib/ntfy-sh";
      mode = "-";
      user = "-";
      group = "-";
    }
  ];

  services.restic.backups.b2.paths = [ "/persist/var/lib/ntfy-sh" ];
}
