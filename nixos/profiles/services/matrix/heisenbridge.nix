{ config, ... }:
{
  sops.secrets."heisenbridge_appservice_hs_token" = {
    opentofu = {
      enable = true;
    };
  };

  sops.secrets."heisenbridge_appservice_as_token" = {
    opentofu = {
      enable = true;
    };
  };

  services.matrix-synapse.settings = {
    app_service_config_files = [ "/run/credentials/matrix-synapse.service/heisenbridge" ];
  };

  systemd.services.matrix-synapse.serviceConfig = {
    LoadCredential = [
      "heisenbridge:${config.sops.templates."heisenbridge_appservice_registration".path}"
    ];
  };

  sops.templates."heisenbridge_appservice_registration" = {
    path = "/var/lib/heisenbridge/registration.yml";
    owner = config.systemd.services.heisenbridge.serviceConfig.User;
    content = builtins.toJSON {
      id = "heisenbridge";
      namespaces = {
        aliases = [ ];
        rooms = [ ];
        users = [
          {
            exclusive = true;
            regex = "@irc_.*";
          }
        ];
      };
      rate_limited = false;
      sender_localpart = "heisenbridge";
      url = "http://127.0.0.1:${toString config.ports.heisenbridge}";
      as_token = config.sops.placeholder."heisenbridge_appservice_as_token";
      hs_token = config.sops.placeholder."heisenbridge_appservice_hs_token";
    };
    restartUnits = [
      "heisenbridge.service"
      "matrix-synapse.service"
    ];
  };

  services.heisenbridge = {
    enable = true;
    homeserver = "http://127.0.0.1:${toString config.ports.matrix-synapse}";
    address = "127.0.0.1";
    port = config.ports.heisenbridge;
    owner = "@rebmit:rebmit.moe";
  };
}
