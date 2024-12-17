{ config, ... }:
{
  services.miniflux = {
    enable = true;
    config = rec {
      BASE_URL = "https://miniflux.rebmit.moe";
      LISTEN_ADDR = "127.0.0.1:${toString config.networking.ports.miniflux}";
      CREATE_ADMIN = 0;
      OAUTH2_PROVIDER = "oidc";
      OAUTH2_CLIENT_ID = "miniflux";
      OAUTH2_REDIRECT_URL = "${BASE_URL}/oauth2/oidc/callback";
      OAUTH2_OIDC_PROVIDER_NAME = "keycloak.rebmit.moe";
      OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://keycloak.rebmit.moe/realms/rebmit";
      OAUTH2_USER_CREATION = 1;
    };
  };

  services.caddy.virtualHosts."miniflux.rebmit.moe" = {
    extraConfig = ''
      reverse_proxy ${config.services.miniflux.config.LISTEN_ADDR}
    '';
  };
}
