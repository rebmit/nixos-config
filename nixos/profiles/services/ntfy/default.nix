{
  config,
  lib,
  mylib,
  ...
}:
let
  inherit (lib.modules) mkForce;

  cfg = config.services.ntfy-sh;
in
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
    AmbientCapabilities = mkForce [ "" ];
    CapabilityBoundingSet = mkForce [ "" ];
    DynamicUser = mkForce false;
  };

  services.caddy.virtualHosts."push.rebmit.moe" = {
    serverAliases = [ "push.workers.moe" ];
    extraConfig = ''
      reverse_proxy ${cfg.settings.listen-http}
    '';
  };

  preservation.preserveAt."/persist".directories = [ "/var/lib/ntfy-sh" ];
}
