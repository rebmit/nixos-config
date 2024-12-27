{
  config,
  lib,
  mylib,
  data,
  ...
}:
{
  sops.secrets."cloudflare_origin_ntfy_private_key" = {
    opentofu = {
      enable = true;
    };
    restartUnits = [ "caddy.service" ];
  };

  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "https://ntfy.rebmit.workers.moe";
      listen-http = "127.0.0.1:${toString config.networking.ports.ntfy}";
      auth-default-access = "deny-all";
      behind-proxy = true;
    };
  };

  systemd.services.ntfy-sh.serviceConfig = mylib.misc.serviceHardened // {
    AmbientCapabilities = lib.mkForce [ "" ];
    CapabilityBoundingSet = lib.mkForce [ "" ];
    DynamicUser = lib.mkForce false;
  };

  systemd.services.caddy.serviceConfig = {
    LoadCredential = [
      "cloudflare_aop_ntfy_ca_cert:${builtins.toFile "cloudflare_aop_ca_certificate" data.cloudflare_aop_ca_certificate}"
      "cloudflare_origin_ntfy_cert:${builtins.toFile "cloudflare_origin_ntfy_certificate" data.cloudflare_origin_ntfy_certificate}"
      "cloudflare_origin_ntfy_key:${config.sops.secrets."cloudflare_origin_ntfy_private_key".path}"
    ];
  };

  services.caddy.virtualHosts."ntfy.rebmit.workers.moe" =
    let
      credentialPath = "/run/credentials/caddy.service";
    in
    {
      extraConfig = ''
        tls ${credentialPath}/cloudflare_origin_ntfy_cert ${credentialPath}/cloudflare_origin_ntfy_key {
          client_auth {
            mode require_and_verify
            trust_pool file ${credentialPath}/cloudflare_aop_ntfy_ca_cert
          }
        }
        reverse_proxy ${config.services.ntfy-sh.settings.listen-http}
      '';
    };

  preservation.preserveAt."/persist".directories = [
    {
      directory = "/var/lib/ntfy-sh";
      mode = "-";
      user = "-";
      group = "-";
    }
  ];

  services.restic.backups.b2.paths = [ "/persist/var/lib/ntfy-sh" ];
}
