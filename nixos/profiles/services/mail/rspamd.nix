# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/3b03efb676ea602575c916b2b8bc9d9cd13b0d85/nixos/hcloud/iad0/postfix.nix (MIT License)
{ config, ... }:
{
  sops.secrets."mail/dkim-20241219" = {
    sopsFile = config.sops.secretFiles.host;
    path = "/var/lib/rspamd/dkim/20241219.key";
    owner = config.services.rspamd.user;
  };

  services.postfix.settings.main = {
    smtpd_milters = [ "unix:/run/rspamd/postfix.sock" ];
    non_smtpd_milters = [ "unix:/run/rspamd/postfix.sock" ];
  };

  services.rspamd = {
    enable = true;
    workers = {
      controller = {
        bindSockets = [ "localhost:${toString config.ports.rspamd-controller}" ];
      };
      rspamd_proxy = {
        bindSockets = [
          {
            mode = "0666";
            socket = "/run/rspamd/postfix.sock";
          }
        ];
      };
    };
    locals = {
      "worker-controller.inc".text = ''
        secure_ip = ["127.0.0.1", "::1"];
      '';
      "worker-proxy.inc".text = ''
        upstream "local" {
          self_scan = yes;
        }
      '';
      "redis.conf".text = ''
        servers = "127.0.0.1:${toString config.ports.rspamd-redis}";
      '';
      "classifier-bayes.conf".text = ''
        autolearn = true;
      '';
      "dkim_signing.conf".text = ''
        path = "${config.sops.secrets."mail/dkim-20241219".path}";
        selector = "20241219";
        allow_username_mismatch = true;
        allow_envfrom_empty = true;
      '';
    };
  };

  services.redis.servers.rspamd = {
    enable = true;
    bind = "127.0.0.1";
    port = config.ports.rspamd-redis;
  };

  preservation.directories = [
    "/var/lib/rspamd"
    "/var/lib/redis-rspamd"
  ];
}
