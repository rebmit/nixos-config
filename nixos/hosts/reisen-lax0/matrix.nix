# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/3b03efb676ea602575c916b2b8bc9d9cd13b0d85/nixos/hcloud/hio0/matrix.nix
{
  config,
  pkgs,
  ...
}:
let
  conf = {
    default_server_config = {
      "m.homeserver" = {
        base_url = config.services.matrix-synapse.settings.public_baseurl;
        server_name = config.services.matrix-synapse.settings.server_name;
      };
    };
    show_labs_settings = true;
  };
in
{
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
  };

  services.postgresqlBackup = {
    enable = true;
    location = "/var/lib/backup/postgresql";
    backupAll = true;
    compression = "zstd";
  };

  sops.secrets."synapse/signing-key" = {
    sopsFile = config.sops.secretFiles.host;
  };

  sops.secrets."synapse/mautrix-telegram" = {
    sopsFile = config.sops.secretFiles.host;
  };

  systemd.services.matrix-synapse.serviceConfig.LoadCredential = [
    "telegram:/var/lib/mautrix-telegram/telegram-registration.yaml"
    "irc:/var/lib/heisenbridge/registration.yml"
  ];

  services.matrix-synapse = {
    enable = false;
    withJemalloc = true;
    settings = {
      server_name = "rebmit.moe";
      public_baseurl = "https://matrix.rebmit.moe";
      signing_key_path = config.sops.secrets."synapse/signing-key".path;

      app_service_config_files = [
        "/run/credentials/matrix-synapse.service/telegram"
        "/run/credentials/matrix-synapse.service/irc"
      ];

      enable_registration = true;
      registration_requires_token = true;

      listeners = [
        {
          bind_addresses = [ "127.0.0.1" ];
          port = 8196;
          tls = false;
          type = "http";
          x_forwarded = true;
          resources = [
            {
              compress = true;
              names = [
                "client"
                "federation"
              ];
            }
          ];
        }
      ];

      media_retention = {
        remote_media_lifetime = "14d";
      };

      experimental_features = {
        # Room summary api
        msc3266_enabled = true;
        # Removing account data
        msc3391_enabled = true;
        # Thread notifications
        msc3773_enabled = true;
        # Remotely toggle push notifications for another client
        msc3881_enabled = true;
        # Remotely silence local notifications
        msc3890_enabled = true;
      };
    };
  };

  services.caddy = {
    virtualHosts."matrix.rebmit.moe".extraConfig = ''
      reverse_proxy /_matrix/* 127.0.0.1:8196
      reverse_proxy /_synapse/* 127.0.0.1:8196

      header {
        X-Frame-Options SAMEORIGIN
        X-Content-Type-Options nosniff
        X-XSS-Protection "1; mode=block"
        Content-Security-Policy "frame-ancestors 'self'"
      }

      file_server
      root * "${pkgs.element-web.override { inherit conf; }}"
    '';
  };
}
