# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/3b03efb676ea602575c916b2b8bc9d9cd13b0d85/nixos/hcloud/iad0/knot.nix (MIT License)
{
  config,
  inputs,
  lib,
  pkgs,
  data,
  ...
}:
let
  secondary = lib.listToAttrs (
    builtins.map (
      name:
      lib.nameValuePair name {
        id = name;
        address = [
          (builtins.elemAt data.hosts.${name}.endpoints_v4 0)
          (builtins.elemAt data.hosts.${name}.endpoints_v6 0)
        ];
      }
    ) data.nameservers.secondary
    ++ lib.singleton (
      lib.nameValuePair "he-ns1" {
        id = "he-ns1";
        address = [
          "216.218.130.2"
          "2001:470:100::2"
        ];
      }
    )
  );
in
{
  services.knot = {
    enable = true;
    keyFiles = [ "/run/credentials/knot.service/tsig_ddns_conf" ];
    settings = {
      server = {
        async-start = true;
        tcp-reuseport = true;
        tcp-fastopen = true;
        edns-client-subnet = true;
        automatic-acl = true;
        listen = [
          "0.0.0.0"
          "::"
        ];
      };
      log = [
        {
          target = "syslog";
          any = "info";
        }
      ];
      remote = [
        {
          id = "cloudflare";
          address = [
            "1.1.1.1"
            "1.0.0.1"
            "2606:4700:4700::1111"
            "2606:4700:4700::1001"
          ];
        }
      ] ++ builtins.attrValues secondary;
      remotes = [
        {
          id = "secondary";
          remote = builtins.attrNames secondary;
        }
      ];
      acl = [
        {
          id = "ddns";
          key = "ddns";
          action = "update";
          update-owner = "name";
          update-owner-match = "sub";
          update-owner-name = "dyn";
        }
        {
          id = "he-slave";
          address = [
            "216.218.133.2"
            "2001:470:600::2"
          ];
          action = "transfer";
        }
      ];
      policy = [
        {
          algorithm = "ed25519";
          id = "default";
          ksk-lifetime = "365d";
          ksk-shared = true;
          ksk-submission = "default";
          nsec3 = true;
          nsec3-iterations = "0";
          nsec3-salt-length = "0";
          signing-threads = "4";
        }
      ];
      submission = [
        {
          check-interval = "10m";
          id = "default";
          parent = "cloudflare";
        }
      ];
      template = [
        {
          id = "default";
          notify = "secondary";
          global-module = "mod-rrl/default";
          catalog-role = "member";
          catalog-zone = "catalog";
          dnssec-policy = "default";
          dnssec-signing = true;
          serial-policy = "unixtime";
          semantic-checks = true;
          zonefile-load = "difference-no-serial";
          zonefile-sync = "-1";
          journal-content = "all";
        }
        {
          id = "catalog";
          notify = "secondary";
          catalog-role = "generate";
          serial-policy = "unixtime";
          zonefile-load = "difference-no-serial";
          zonefile-sync = "-1";
          journal-content = "all";
        }
      ];
      mod-rrl = [
        {
          id = "default";
          rate-limit = "200";
          slip = "2";
        }
      ];
      zone = [
        {
          domain = "catalog";
          template = "catalog";
        }
        {
          domain = "rebmit.link";
          acl = [
            "ddns"
            "he-slave"
          ];
          file = pkgs.writeText "db.link.rebmit" (
            import ../../../../zones/rebmit.link.nix {
              inherit (inputs) dns;
              inherit lib config;
            }
          );
        }
        {
          domain = "rebmit.moe";
          acl = [ "he-slave" ];
          file = pkgs.writeText "db.moe.rebmit" (
            import ../../../../zones/rebmit.moe.nix {
              inherit (inputs) dns;
              inherit lib config;
            }
          );
        }
        {
          domain = "1.2.e.7.0.a.a.e.0.a.2.ip6.arpa";
          acl = [ "he-slave" ];
          file = pkgs.writeText "db.arpa.ip6.2.a.0.e.a.a.0.7.e.2.1" (
            import ../../../../zones/1.2.e.7.0.a.a.e.0.a.2.ip6.arpa.nix {
              inherit (inputs) dns;
              inherit lib config;
            }
          );
        }
      ];
    };
  };

  sops.secrets."knot_ddns_tsig_secret" = {
    opentofu = {
      enable = true;
    };
    restartUnits = [ "knot.service" ];
  };

  sops.templates."knot_tsig_ddns_conf".content = ''
    key:
    - id: ddns
      algorithm: hmac-sha256
      secret: ${config.sops.placeholder."knot_ddns_tsig_secret"}
  '';

  systemd.services.knot.serviceConfig = {
    LoadCredential = [ "tsig_ddns_conf:${config.sops.templates."knot_tsig_ddns_conf".path}" ];
  };

  preservation.preserveAt."/persist".directories = [ "/var/lib/knot" ];
}
