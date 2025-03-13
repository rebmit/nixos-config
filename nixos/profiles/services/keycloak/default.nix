{
  config,
  pkgs,
  mylib,
  ...
}:
{
  services.keycloak = {
    enable = true;
    database = {
      type = "postgresql";
      passwordFile = "${pkgs.writeText "keycloak-db-password" "keycloak"}";
    };
    settings = {
      http-enabled = true;
      http-host = "127.0.0.1";
      http-port = config.ports.keycloak;
      proxy-headers = "xforwarded";
      hostname = "idp.rebmit.moe";
      cache = "local";
    };
  };

  systemd.services.keycloak.serviceConfig = mylib.misc.serviceHardened // {
    MemoryDenyWriteExecute = false;
  };

  services.caddy.virtualHosts."idp.rebmit.moe" = {
    extraConfig = ''
      reverse_proxy ${config.services.keycloak.settings.http-host}:${toString config.services.keycloak.settings.http-port}
    '';
  };
}
