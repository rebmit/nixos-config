# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/3b03efb676ea602575c916b2b8bc9d9cd13b0d85/nixos/hcloud/iad0/postfix.nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.dovecot2;
  maildir = "/var/lib/mail";
in
{
  sops.secrets."mail/dovecot-passdb" = {
    sopsFile = config.sops.secretFiles.host;
    owner = cfg.user;
  };

  services.postfix = {
    config = {
      virtual_transport = "lmtp:unix:/run/dovecot2/lmtp";
    };
    masterConfig =
      let
        mkKeyVal = opt: val: [
          "-o"
          (opt + "=" + val)
        ];
        mkOpts = opts: lib.concatLists (lib.mapAttrsToList mkKeyVal opts);
      in
      {
        "127.0.0.1:${toString config.networking.ports.smtp-submission}".args = mkOpts {
          smtpd_sasl_auth_enable = "yes";
          smtpd_sasl_type = "dovecot";
          smtpd_sasl_path = "/run/dovecot2/auth-postfix";
        };
      };
  };

  systemd.tmpfiles.rules = [
    "d ${maildir} 0700 ${cfg.mailUser} ${cfg.mailGroup} -"
  ];

  services.dovecot2 = {
    enable = true;
    modules = [ pkgs.dovecot_pigeonhole ];
    mailUser = "dovemail";
    mailGroup = "dovemail";
    sieve = {
      extensions = [ "fileinto" ];
      scripts = {
        after = builtins.toFile "after.sieve" ''
          require "fileinto";
          if header :is "X-Spam" "Yes" {
              fileinto "Junk";
              stop;
          }
        '';
      };
    };
    enableDHE = false;
    enableImap = true;
    enableLmtp = true;
    enablePAM = false;
    enablePop3 = false;
    enableQuota = false;
    mailPlugins.perProtocol.lmtp.enable = [ "sieve" ];
    mailLocation = "maildir:~";
    mailboxes = {
      Drafts = {
        auto = "subscribe";
        specialUse = "Drafts";
      };
      Sent = {
        auto = "subscribe";
        specialUse = "Sent";
      };
      Trash = {
        auto = "subscribe";
        specialUse = "Trash";
      };
      Junk = {
        auto = "subscribe";
        specialUse = "Junk";
      };
      Archive = {
        auto = "subscribe";
        specialUse = "Archive";
      };
    };
    pluginSettings = {
      sieve_after = "/var/lib/dovecot/sieve/after";
    };
    extraConfig = ''
      listen = 127.0.0.1
      haproxy_trusted_networks = 127.0.0.1/8

      default_internal_user  = ${cfg.user}
      default_internal_group = ${cfg.group}

      auth_username_format   = %Ln
      mail_home = ${maildir}/%u

      service imap-login {
        unix_listener imap-caddy {
          mode    = 0666
        }
        inet_listener imap {
          port = 0
        }
        inet_listener imaps {
          port = 0
        }
      }

      service auth {
        unix_listener auth-postfix {
          mode = 0660
          user = postfix
          group = postfix
        }
      }

      userdb {
        driver = static
        args = uid=${cfg.mailUser} gid=${cfg.mailGroup}
      }

      passdb {
        driver = passwd-file
        args = ${config.sops.secrets."mail/dovecot-passdb".path}
      }
    '';
  };

  services.caddy.virtualHosts."${config.networking.fqdn}" = { };

  services.caddy.globalConfig = ''
    layer4 {
      :${toString config.networking.ports.imap-tls} {
        route {
          tls {
            connection_policy {
              alpn imap
              match {
                sni ${config.networking.fqdn}
              }
            }
          }
          proxy {
            upstream unix//run/dovecot2/imap-caddy
          }
        }
      }
      :${toString config.networking.ports.smtp-tls} {
        route {
          tls {
            connection_policy {
              match {
                sni ${config.networking.fqdn}
              }
            }
          }
          proxy {
            proxy_protocol v2
            upstream 127.0.0.1:${toString config.networking.ports.smtp-submission}
          }
        }
      }
    }
  '';

  services.restic.backups.b2.paths = [ maildir ];
}
