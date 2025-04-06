# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/3b03efb676ea602575c916b2b8bc9d9cd13b0d85/nixos/hcloud/iad0/knot.nix (MIT License)
{
  config,
  inputs,
  lib,
  mylib,
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
        key = "e7816061-ec90-489c-8f3b-18206fa2d3d2";
        address = [
          (builtins.elemAt data.hosts.${name}.endpoints_v4 0)
          (builtins.elemAt data.hosts.${name}.endpoints_v6 0)
        ];
      }
    ) data.nameservers.secondary
    ++ lib.singleton (
      lib.nameValuePair "he-ns1" {
        id = "he-ns1";
        key = "1c8fc5fc-41a3-4c83-b663-07828405e2ec";
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
    keyFiles = [
      "/run/credentials/knot.service/ddns-tsig-conf"
      "/run/credentials/knot.service/he-tsig-conf"
      "/run/credentials/knot.service/reisen-tsig-conf"
    ];
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
          key = "1c8fc5fc-41a3-4c83-b663-07828405e2ec";
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
              inherit lib config mylib;
            }
          );
        }
        {
          domain = "rebmit.moe";
          acl = [ "he-slave" ];
          file = pkgs.writeText "db.moe.rebmit" (
            import ../../../../zones/rebmit.moe.nix {
              inherit (inputs) dns;
              inherit lib config mylib;
            }
          );
        }
        {
          domain = "rebmit.workers.moe";
          acl = [ "he-slave" ];
          file = pkgs.writeText "db.moe.workers.rebmit" (
            import ../../../../zones/rebmit.workers.moe.nix {
              inherit (inputs) dns;
              inherit lib config mylib;
            }
          );
        }
        {
          domain = "1.2.e.7.0.a.a.e.0.a.2.ip6.arpa";
          acl = [ "he-slave" ];
          file = pkgs.writeText "db.arpa.ip6.2.a.0.e.a.a.0.7.e.2.1" (
            import ../../../../zones/1.2.e.7.0.a.a.e.0.a.2.ip6.arpa.nix {
              inherit (inputs) dns;
              inherit lib config mylib;
            }
          );
        }
      ];
    };
  };

  systemd.services.knot.serviceConfig = {
    LoadCredential = [
      "ddns-tsig-conf:${config.sops.templates.knot-ddns-tsig-conf.path}"
      "he-tsig-conf:${config.sops.templates.knot-he-tsig-conf.path}"
      "reisen-tsig-conf:${config.sops.templates.knot-reisen-tsig-conf.path}"
    ];
  };

  sops.templates.knot-ddns-tsig-conf = {
    content = ''
      key:
      - id: ddns
        algorithm: hmac-sha256
        secret: ${config.sops.placeholder.knot-ddns-tsig-secret}
    '';
    restartUnits = [ "knot.service" ];
  };

  sops.templates.knot-he-tsig-conf = {
    content = ''
      key:
      - id: 1c8fc5fc-41a3-4c83-b663-07828405e2ec
        algorithm: hmac-sha256
        secret: ${config.sops.placeholder.knot-he-tsig-secret}
    '';
    restartUnits = [ "knot.service" ];
  };

  sops.templates.knot-reisen-tsig-conf = {
    content = ''
      key:
      - id: e7816061-ec90-489c-8f3b-18206fa2d3d2
        algorithm: hmac-sha256
        secret: ${config.sops.placeholder.knot-reisen-tsig-secret}
    '';
    restartUnits = [ "knot.service" ];
  };

  sops.secrets.knot-ddns-tsig-secret.opentofu.enable = true;
  sops.secrets.knot-he-tsig-secret.opentofu.enable = true;
  sops.secrets.knot-reisen-tsig-secret.opentofu.enable = true;

  preservation.preserveAt."/persist".directories = [ "/var/lib/knot" ];
}
