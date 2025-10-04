# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/3b03efb676ea602575c916b2b8bc9d9cd13b0d85/modules/dns/secondary/default.nix (MIT License)
{
  config,
  lib,
  data,
  ...
}:
let
  primary = data.hosts.${data.nameservers.primary};
in
{
  services.knot = {
    enable = true;
    keyFiles = [
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
          id = "transfer";
          key = "e7816061-ec90-489c-8f3b-18206fa2d3d2";
          address = [
            (builtins.elemAt primary.endpoints_v4 0)
            (builtins.elemAt primary.endpoints_v6 0)
          ];
        }
      ];
      template = [
        {
          id = "default";
          global-module = "mod-rrl/default";
        }
        {
          id = "member";
          master = "transfer";
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
          master = "transfer";
          catalog-role = "interpret";
          catalog-template = "member";
        }
      ];
    };
  };

  systemd.network.netdevs."40-local" = {
    netdevConfig = {
      Name = "local";
      Kind = "dummy";
    };
  };

  systemd.network.networks."40-local" = {
    matchConfig.Name = "local";
    networkConfig = {
      Address = [ "2a0e:aa07:e210:100::1" ];
      DHCP = false;
      IPv6AcceptRA = false;
    };
  };

  services.bird.config =
    lib.mkIf (config.services.enthalpy.enable && config.services.enthalpy.exit.enable)
      (
        lib.mkOrder 1600 ''
          protocol static {
            ipv6 sadr {
              table enthalpy6;
            };
            route 2a0e:aa07:e210:100::/56 from ::/0 unreachable;
          }
        ''
      );

  systemd.services.knot.serviceConfig = {
    LoadCredential = [
      "reisen-tsig-conf:${config.sops.templates.knot-reisen-tsig-conf.path}"
    ];
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

  sops.secrets.knot-reisen-tsig-secret.opentofu.enable = true;

  preservation.directories = [ "/var/lib/knot" ];
}
