# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/3b03efb676ea602575c916b2b8bc9d9cd13b0d85/modules/dns/secondary/default.nix
{ ... }:
let
  common = import ../../../../zones/common.nix;
  primary = common.hosts.${common.primary};
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
          id = "transfer";
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
          zonemd-verify = true;
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

  preservation.preserveAt."/persist".directories = [
    {
      directory = "/var/lib/knot";
      mode = "0700";
    }
  ];
}
