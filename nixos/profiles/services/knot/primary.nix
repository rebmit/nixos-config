# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/3b03efb676ea602575c916b2b8bc9d9cd13b0d85/nixos/hcloud/iad0/knot.nix
{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  common = import ../../../../zones/common.nix;
  secondary = lib.listToAttrs (
    builtins.map (
      name:
      lib.nameValuePair name {
        id = name;
        address = [
          (builtins.elemAt common.hosts.${name}.endpoints_v4 0)
          (builtins.elemAt common.hosts.${name}.endpoints_v6 0)
        ];
      }
    ) common.secondary
  );
in
{
  services.knot = {
    enable = true;
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
          zonemd-generate = "zonemd-sha512";
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
          file = pkgs.writeText "db.link.rebmit" (
            import ../../../../zones/rebmit.link.nix {
              inherit (inputs) dns;
              inherit lib;
            }
          );
        }
        {
          domain = "rebmit.moe";
          file = pkgs.writeText "db.moe.rebmit" (
            import ../../../../zones/rebmit.moe.nix {
              inherit (inputs) dns;
              inherit lib;
            }
          );
        }
      ];
    };
  };

  services.restic.backups.b2.paths = [ "/var/lib/knot" ];
}
