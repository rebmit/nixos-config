{ config, ... }:
{
  services.vaultwarden = {
    enable = true;
    dbBackend = "sqlite";
    backupDir = "/var/lib/backup/vaultwarden";
    config = {
      DOMAIN = "https://vault.rebmit.moe";
      SIGNUPS_ALLOWED = false;
      EMERGENCY_ACCESS_ALLOWED = false;
      SENDS_ALLOWED = false;
      ORG_CREATION_USERS = "none";
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = config.ports.vaultwarden;
      IP_HEADER = "X-Forwarded-For";
      ENABLE_WEBSOCKET = false;
    };
  };

  services.caddy.virtualHosts."vault.rebmit.moe" = {
    extraConfig = with config.services.vaultwarden.config; ''
      reverse_proxy ${ROCKET_ADDRESS}:${toString ROCKET_PORT}
    '';
  };

  preservation.preserveAt."/persist".directories = [
    "/var/lib/vaultwarden"
    config.services.vaultwarden.backupDir
  ];
}
