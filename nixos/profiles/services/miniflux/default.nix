{ config, ... }:
{
  sops.secrets."miniflux/oidc-client-secret" = {
    sopsFile = config.sops.secretFiles.host;
  };

  systemd.services.miniflux.serviceConfig = {
    LoadCredential = [
      "oidc-client-secret:${config.sops.secrets."miniflux/oidc-client-secret".path}"
    ];
  };

  services.miniflux = {
    enable = true;
    config = rec {
      BASE_URL = "https://rss.rebmit.moe";
      LISTEN_ADDR = "127.0.0.1:${toString config.ports.miniflux}";
      CREATE_ADMIN = 0;
      OAUTH2_PROVIDER = "oidc";
      OAUTH2_CLIENT_ID = "miniflux";
      OAUTH2_CLIENT_SECRET_FILE = "/run/credentials/miniflux.service/oidc-client-secret";
      OAUTH2_REDIRECT_URL = "${BASE_URL}/oauth2/oidc/callback";
      OAUTH2_OIDC_PROVIDER_NAME = "idp.rebmit.moe";
      OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://idp.rebmit.moe/realms/rebmit";
      OAUTH2_USER_CREATION = 1;
    };
  };

  services.caddy.virtualHosts."rss.rebmit.moe" = {
    extraConfig = ''
      reverse_proxy ${config.services.miniflux.config.LISTEN_ADDR}
    '';
  };
}
