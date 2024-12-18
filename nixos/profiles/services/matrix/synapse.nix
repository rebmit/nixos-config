# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/3b03efb676ea602575c916b2b8bc9d9cd13b0d85/nixos/hcloud/hio0/matrix.nix
# https://github.com/linyinfeng/dotfiles/blob/b618b0fd16fb9c79ab7199ed51c4c0f98a392cea/nixos/profiles/services/matrix/default.nix
{ config, pkgs, ... }:
{
  sops.secrets."synapse/signing-key" = {
    sopsFile = config.sops.secretFiles.host;
    owner = config.systemd.services.matrix-synapse.serviceConfig.User;
  };

  sops.secrets."synapse/oidc-client-secret" = {
    sopsFile = config.sops.secretFiles.host;
    owner = config.systemd.services.matrix-synapse.serviceConfig.User;
  };

  services.matrix-synapse = {
    enable = true;
    withJemalloc = true;
    settings = {
      server_name = "rebmit.moe";
      public_baseurl = "https://matrix.rebmit.moe";

      dynamic_thumbnails = true;
      enable_registration = true;
      registration_requires_token = true;

      signing_key_path = config.sops.secrets."synapse/signing-key".path;

      listeners = [
        {
          bind_addresses = [ "127.0.0.1" ];
          port = config.networking.ports.matrix-synapse;
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

      oidc_providers = [
        {
          idp_id = "keycloak";
          idp_name = "keycloak.rebmit.moe";
          issuer = "https://keycloak.rebmit.moe/realms/rebmit";
          client_id = "synapse";
          client_secret_path = config.sops.secrets."synapse/oidc-client-secret".path;
          scopes = [
            "openid"
            "profile"
          ];
          allow_existing_users = true;
          backchannel_logout_enabled = true;
          user_mapping_provider.config = {
            confirm_localpart = true;
            localpart_template = "{{ user.preferred_username }}";
            display_name_template = "{{ user.name }}";
          };
        }
      ];

      media_retention = {
        remote_media_lifetime = "14d";
      };
    };
  };

  services.caddy.virtualHosts."matrix.rebmit.moe" = {
    extraConfig = ''
      reverse_proxy /_matrix/* 127.0.0.1:${toString config.networking.ports.matrix-synapse}
      reverse_proxy /_synapse/* 127.0.0.1:${toString config.networking.ports.matrix-synapse}

      header {
        X-Frame-Options SAMEORIGIN
        X-Content-Type-Options nosniff
        X-XSS-Protection "1; mode=block"
        Content-Security-Policy "frame-ancestors 'self'"
      }

      file_server
      root * "${
        pkgs.element-web.override {
          conf = {
            default_server_config = {
              "m.homeserver" = {
                base_url = config.services.matrix-synapse.settings.public_baseurl;
                server_name = config.services.matrix-synapse.settings.server_name;
              };
            };
            show_labs_settings = true;
          };
        }
      }"
    '';
  };
}
