{
  config,
  pkgs,
  mylib,
  ...
}:
{
  sops.secrets."mautrix_telegram_appservice_hs_token" = {
    opentofu = {
      enable = true;
    };
  };

  sops.secrets."mautrix_telegram_appservice_as_token" = {
    opentofu = {
      enable = true;
    };
  };

  sops.secrets."synapse/mautrix-telegram-bot-token" = {
    sopsFile = config.sops.secretFiles.host;
  };

  services.matrix-synapse.settings = {
    app_service_config_files = [ "/run/credentials/matrix-synapse.service/mautrix-telegram" ];
  };

  systemd.services.matrix-synapse.serviceConfig = {
    LoadCredential = [
      "mautrix-telegram:${config.sops.templates."mautrix_telegram_appservice_registration".path}"
    ];
  };

  sops.templates."mautrix_telegram_appservice_registration" = {
    content = builtins.toJSON {
      id = "telegram";
      namespaces = {
        aliases = [
          {
            exclusive = true;
            regex = "\\#telegram_.*:rebmit\\.moe";
          }
        ];
        rooms = [ ];
        users = [
          {
            exclusive = true;
            regex = "@telegram_.*:rebmit\\.moe";
          }
          {
            exclusive = true;
            regex = "@telegrambot:rebmit\\.moe";
          }
        ];
      };
      rate_limited = false;
      sender_localpart = "mautrix-telegram";
      url = "http://127.0.0.1:${toString config.networking.ports.mautrix-telegram}";
      as_token = config.sops.placeholder."mautrix_telegram_appservice_as_token";
      hs_token = config.sops.placeholder."mautrix_telegram_appservice_hs_token";
      de.sorunome.msc2409.push_ephemeral = true;
      push_ephemeral = true;
    };
    restartUnits = [
      "matrix-synapse.service"
    ];
  };

  sops.templates."mautrix_telegram_config" = {
    content = ''
      MAUTRIX_TELEGRAM_APPSERVICE_AS_TOKEN=${
        config.sops.placeholder."mautrix_telegram_appservice_as_token"
      }
      MAUTRIX_TELEGRAM_APPSERVICE_HS_TOKEN=${
        config.sops.placeholder."mautrix_telegram_appservice_hs_token"
      }
      MAUTRIX_TELEGRAM_TELEGRAM_BOT_TOKEN=${config.sops.placeholder."synapse/mautrix-telegram-bot-token"}
    '';
    restartUnits = [
      "mautrix-telegram.service"
    ];
  };

  services.mautrix-telegram = {
    enable = true;
    environmentFile = config.sops.templates."mautrix_telegram_config".path;
    serviceDependencies = [ config.systemd.services.matrix-synapse.name ];
    settings = {
      homeserver = {
        address = "http://127.0.0.1:${toString config.networking.ports.matrix-synapse}";
        domain = config.services.matrix-synapse.settings.server_name;
      };
      appservice = {
        id = "telegram";
        address = "http://127.0.0.1:${toString config.networking.ports.mautrix-telegram}";
        database = "postgres:///mautrix-telegram?host=/run/postgresql";
        hostname = "127.0.0.1";
        port = config.networking.ports.mautrix-telegram;
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
        animated_sticker = {
          target = "webp";
          convert_from_webm = true;
        };
        permissions = {
          "*" = "relaybot";
          "@rebmit:rebmit.moe" = "admin";
        };
        relaybot = {
          authless_portals = false;
        };
        encryption = {
          allow = true;
        };
      };
      telegram = {
        api_id = 611335;
        api_hash = "d524b414d21f4d37f08684c1df41ac9c";
        device_info = {
          app_version = pkgs.tdesktop.version;
        };
        force_refresh_interval_seconds = 3600;
      };
      logging = {
        loggers = {
          mau.level = "WARNING";
          telethon.level = "WARNING";
        };
      };
    };
  };

  systemd.services.mautrix-telegram.serviceConfig = mylib.misc.serviceHardened;
}
