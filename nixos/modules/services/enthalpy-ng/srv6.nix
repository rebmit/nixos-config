# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/3b03efb676ea602575c916b2b8bc9d9cd13b0d85/modules/gravity/default.nix
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
  inherit (lib.attrsets) mapAttrsToList;
  inherit (lib.lists) singleton;
  inherit (mylib.network) cidr;

  cfg = config.services.enthalpy-ng;
  netnsCfg = config.networking.netns-ng.enthalpy-ng;
in
{
  options.services.enthalpy-ng.srv6 = {
    enable = mkEnableOption "segment routing over IPv6";
    prefix = mkOption {
      type = types.str;
      default = cidr.subnet 4 6 cfg.prefix;
      description = ''
        Prefix used for SRv6 actions.
      '';
    };
    actions = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = ''
        List of SRv6 actions configured for this node.
      '';
    };
  };

  config = mkIf (cfg.enable && cfg.srv6.enable) {
    services.enthalpy-ng.srv6.actions = {
      "${cidr.host 1 cfg.srv6.prefix}" = "End.DT6 table ${toString netnsCfg.misc.routingTables.main}";
    };

    networking.netns-ng.enthalpy-ng = {
      interfaces.lo = {
        routes = singleton {
          cidr = "::/0";
          type = "blackhole";
          table = netnsCfg.misc.routingTables.localsid;
        };
      };

      interfaces.enthalpy = {
        routes = mapAttrsToList (name: value: {
          cidr = name;
          table = netnsCfg.misc.routingTables.localsid;
          extraOptions = {
            encap.seg6local.action = value;
          };
        }) cfg.srv6.actions;
        routingPolicyRules = [
          {
            priority = netnsCfg.misc.routingPolicyPriorities.localsid;
            family = [ "ipv6" ];
            selector = {
              from = cfg.network;
              to = cfg.srv6.prefix;
            };
            action = {
              table = netnsCfg.misc.routingTables.localsid;
            };
          }
        ];
      };
    };
  };
}
