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
    sopsFile = config.sops.secretFiles.get "hosts/reisen-lax0.yaml";
  };

  sops.secrets."synapse/mautrix-telegram" = {
    sopsFile = config.sops.secretFiles.get "hosts/reisen-lax0.yaml";
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

  systemd.services.mautrix-telegram.serviceConfig.RuntimeMaxSec = 86400;

  services.mautrix-telegram = {
    enable = false;
    environmentFile = config.sops.secrets."synapse/mautrix-telegram".path;
    serviceDependencies = [ "matrix-synapse.service" ];
    settings = {
      homeserver = {
        address = "http://127.0.0.1:8196";
        domain = config.services.matrix-synapse.settings.server_name;
      };
      appservice = {
        address = "http://127.0.0.1:29317";
        database = "postgres:///mautrix-telegram?host=/run/postgresql";
        hostname = "127.0.0.1";
        port = 29317;
        provisioning.enabled = false;
      };
      bridge = {
        displayname_template = "{displayname}";
        public_portals = true;
        delivery_error_reports = true;
        incoming_bridge_error_reports = true;
        bridge_matrix_leave = false;
        relay_user_distinguishers = [ ];
        create_group_on_invite = false;
        encryption = {
          allow = true;
          default = true;
        };
        animated_sticker = {
          target = "webp";
          convert_from_webm = true;
        };
        state_event_formats = {
          join = "";
          leave = "";
          name_change = "";
        };
        permissions = {
          "*" = "relaybot";
          "@i:rebmit.moe" = "admin";
        };
        relaybot = {
          authless_portals = false;
        };
      };
      telegram = {
        device_info = {
          app_version = "3.5.2";
        };
      };
      logging = {
        loggers = {
          mau.level = "INFO";
          telethon.level = "INFO";
        };
      };
    };
  };

  services.heisenbridge = {
    enable = false;
    homeserver = "http://127.0.0.1:8196";
    address = "127.0.0.1";
    port = 9898;
    owner = "@i:rebmit.moe";
  };

  services.caddy = {
    virtualHosts."matrix.rebmit.moe".extraConfig = ''
      reverse_proxy /_matrix/* 127.0.0.1:8196
      reverse_proxy /_synapse/client/* 127.0.0.1:8196

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
