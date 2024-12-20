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
      base-url = "https://ntfy.rebmit.moe";
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

  services.caddy.virtualHosts."ntfy.rebmit.moe" = {
    extraConfig = ''
      reverse_proxy ${config.services.ntfy-sh.settings.listen-http}
    '';
  };

  services.restic.backups.b2.paths = [ "/var/lib/ntfy-sh" ];
}
