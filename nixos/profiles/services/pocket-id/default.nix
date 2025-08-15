{ ... }:
{
  services.pocket-id = {
    enable = true;
    settings = {
      APP_URL = "https://idp.rebmit.moe";
      TRUST_PROXY = true;

      DB_PROVIDER = "postgres";
      DB_CONNECTION_STRING = "user=pocket-id dbname=pocket-id host=/run/postgresql";

      UNIX_SOCKET = "/run/pocket-id/pocket-id.sock";
      UNIX_SOCKET_MODE = "0660";

      ANALYTICS_DISABLED = true;
    };
  };

  systemd.services.pocket-id.serviceConfig = {
    RuntimeDirectory = "pocket-id";
    RuntimeDirectoryMode = "0750";
    StateDirectory = "pocket-id";
    StateDirectoryMode = "0750";
    RestrictAddressFamilies = [ "AF_UNIX" ];
  };

  systemd.services.caddy.serviceConfig.SupplementaryGroups = [ "pocket-id" ];

  services.caddy.virtualHosts."idp.rebmit.moe" = {
    extraConfig = ''
      reverse_proxy unix//run/pocket-id/pocket-id.sock
    '';
  };

  services.postgresql = {
    ensureDatabases = [ "pocket-id" ];
    ensureUsers = [
      {
        name = "pocket-id";
        ensureDBOwnership = true;
      }
    ];
  };

  preservation.preserveAt."/persist".directories = [ "/var/lib/pocket-id" ];
}
