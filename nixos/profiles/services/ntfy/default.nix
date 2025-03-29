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
      listen-http = "127.0.0.1:${toString config.ports.ntfy}";
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

  preservation.preserveAt."/persist".directories = [ "/var/lib/ntfy-sh" ];
}
