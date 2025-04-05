{ config, ... }:
{
  services.heisenbridge = {
    enable = true;
    homeserver = "http://127.0.0.1:${toString config.ports.matrix-synapse}";
    address = "127.0.0.1";
    port = config.ports.heisenbridge;
    owner = "@rebmit:rebmit.moe";
  };

  sops.templates.heisenbridge-appservice-registration = {
    path = "/var/lib/heisenbridge/registration.yml";
    owner = config.systemd.services.heisenbridge.serviceConfig.User;
    mode = "0440";
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
      as_token = config.sops.placeholder.heisenbridge-appservice-as-token;
      hs_token = config.sops.placeholder.heisenbridge-appservice-hs-token;
    };
    restartUnits = [
      "heisenbridge.service"
      "matrix-synapse.service"
    ];
  };

  sops.secrets.heisenbridge-appservice-as-token.opentofu.enable = true;
  sops.secrets.heisenbridge-appservice-hs-token.opentofu.enable = true;

  services.matrix-synapse.settings.app_service_config_files = [
    config.sops.templates.heisenbridge-appservice-registration.path
  ];

  systemd.services.matrix-synapse.serviceConfig.SupplementaryGroups = [
    config.systemd.services.heisenbridge.serviceConfig.User
  ];
}
