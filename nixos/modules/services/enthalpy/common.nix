# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/3b03efb676ea602575c916b2b8bc9d9cd13b0d85/modules/gravity/default.nix (MIT License)
{
  inputs,
  config,
  lib,
  pkgs,
  mylib,
  ...
}:
let
  inherit (lib) types;
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.attrsets) mapAttrs' nameValuePair;
  inherit (lib.lists) singleton any;
  inherit (lib.network) ipv6;
  inherit (mylib.network) cidr;

  cfg = config.services.enthalpy;
  netnsCfg = config.networking.netns.enthalpy;
in
{
  options.services.enthalpy = {
    enable = mkEnableOption "enthalpy overlay network, next generation";
    entity = mkOption {
      type = types.str;
      description = ''
        The name of the entity responsible for maintaining this node.
        It should match the name registered in the metadata database.
      '';
    };
    metadata = mkOption {
      type = types.submodule {
        freeformType = (pkgs.formats.json { }).type;
      };
      default = builtins.fromJSON (builtins.readFile "${inputs.enthalpy}/zones/data.json");
      readOnly = true;
      description = ''
        Metadata for the enthalpy network.
      '';
    };
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
    assertions = [
      {
        assertion = any (
          p: (cidr.child cfg.prefix p) || (ipv6.fromString cfg.prefix == ipv6.fromString p)
        ) cfg.metadata."${cfg.entity}".prefixes;
        message = ''
          The prefix for this node must fall within the range of any registered
          prefix in the metadata database of this entity. You can forcibly ignore
          this assertion, but any invalid route announced might be rejected by
          other nodes in enthalpy network.
        '';
      }
      {
        assertion = cidr.length cfg.prefix <= 60;
        message = ''
          The prefix length for this node to be announced should not exceed 60.
          You can forcibly ignore this assertion, but any invalid route announced
          might be rejected by other nodes in enthalpy network.
        '';
      }
    ];

    boot.kernelModules = [ "vrf" ];

    networking.netns.enthalpy = mkMerge [
      {
        sysctl = {
          "net.ipv6.conf.all.forwarding" = 1;
          "net.ipv6.conf.default.forwarding" = 1;

          # https://www.kernel.org/doc/html/latest/networking/vrf.html#applications
          "net.vrf.strict_mode" = 0;
          "net.ipv4.tcp_l3mdev_accept" = 1;
          "net.ipv4.udp_l3mdev_accept" = 1;
          "net.ipv4.raw_l3mdev_accept" = 1;
        };

        netdevs.enthalpy = {
          kind = "dummy";
        };

        interfaces.enthalpy = {
          addresses = [ "${cidr.host 1 cfg.prefix}/128" ];
          routingPolicyRules = singleton {
            priority = netnsCfg.routingPolicyPriorities.l3mdev-unreachable;
            family = [
              "ipv4"
              "ipv6"
            ];
            selector.l3mdev = { };
            action.unreachable = { };
          };
          netdevDependencies = [ netnsCfg.netdevs.enthalpy.service ];
        };

        interfaces."vrf-${cfg.entity}" = {
          addresses = [ "${cidr.host 0 cfg.prefix}/128" ];
          routes = [
            {
              cidr = "::/0";
              table = netnsCfg.routingTables.vrf-other;
            }
            {
              cidr = "::/0";
              table = netnsCfg.routingTables.main;
              extraOptions.from = cfg.network;
            }
          ];
        };
      }
      {
        netdevs = mapAttrs' (
          name: _value:
          nameValuePair "vrf-${name}" {
            kind = "vrf";
            mtu = 1400;
            extraArgs.table =
              if name == cfg.entity then netnsCfg.routingTables.vrf-local else netnsCfg.routingTables.vrf-other;
          }
        ) cfg.metadata;

        interfaces = mapAttrs' (
          name: _value:
          nameValuePair "vrf-${name}" {
            netdevDependencies = [ netnsCfg.netdevs."vrf-${name}".service ];
          }
        ) cfg.metadata;
      }
    ];
  };
}
