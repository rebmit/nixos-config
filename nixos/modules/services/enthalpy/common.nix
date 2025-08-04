# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/3b03efb676ea602575c916b2b8bc9d9cd13b0d85/modules/gravity/default.nix (MIT License)
{
  config,
  lib,
  mylib,
  ...
}:
let
  inherit (lib) types;
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (mylib.network) cidr;

  cfg = config.services.enthalpy;
  netnsCfg = config.networking.netns.enthalpy;
in
{
  options.services.enthalpy = {
    enable = mkEnableOption "enthalpy overlay network, next generation";
    network = mkOption {
      type = types.str;
      default = "2a0e:aa07:e21c::/47";
      readOnly = true;
      description = ''
        Prefix of the enthalpy network.
      '';
    };
    prefix = mkOption {
      type = types.str;
      description = ''
        Prefix to be announced for this node in the enthalpy network.
      '';
    };
  };

  config = mkIf cfg.enable {
    networking.netns.enthalpy = {
      sysctl = {
        "net.ipv6.conf.all.forwarding" = 1;
        "net.ipv6.conf.default.forwarding" = 1;
      };

      netdevs.enthalpy = {
        kind = "dummy";
      };

      interfaces.enthalpy = {
        addresses = [ "${cidr.host 1 cfg.prefix}/128" ];
        netdevDependencies = [ netnsCfg.netdevs.enthalpy.service ];
      };

      confext."resolv.conf" = {
        text = ''
          nameserver 2620:119:35::35
          nameserver 2620:119:53::53
          nameserver 2606:4700:4700::1111
          nameserver 2606:4700:4700::1001
        '';
      };
    };
  };
}
