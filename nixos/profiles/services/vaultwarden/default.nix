{ config, ... }:
let
  cfg = config.services.vaultwarden;
in
{
  services.vaultwarden = {
    enable = true;
    dbBackend = "sqlite";
    backupDir = "/var/lib/backup/vaultwarden";
    config = {
      DOMAIN = "https://vault.rebmit.moe";
      SIGNUPS_ALLOWED = false;
      EMERGENCY_ACCESS_ALLOWED = false;
      ORG_CREATION_USERS = "none";
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = config.ports.vaultwarden;
      IP_HEADER = "X-Forwarded-For";
      ENABLE_WEBSOCKET = false;
    };
  };

  services.caddy.virtualHosts."vault.rebmit.moe" = {
    extraConfig = ''
      reverse_proxy ${cfg.config.ROCKET_ADDRESS}:${toString cfg.config.ROCKET_PORT}
    '';
  };

  preservation.preserveAt."/persist".directories = [
    "/var/lib/vaultwarden"
    config.services.vaultwarden.backupDir
  ];
}
