# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/3b03efb676ea602575c916b2b8bc9d9cd13b0d85/modules/gravity/default.nix (MIT License)
{
  config,
  lib,
  ...
}:
let
  inherit (lib) types;
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (lib.attrsets) attrNames;
  inherit (lib.strings) concatMapStringsSep optionalString splitString;
  inherit (lib.trivial) fromHexString;
  inherit (lib.network) ipv6;

  cfg = config.services.enthalpy;
  netnsCfg = config.networking.netns.enthalpy;

  splitAddress = idx: builtins.elemAt (splitString ":" (ipv6.fromString cfg.prefix).address) idx;
  routerId = (fromHexString (splitAddress 2)) * 65536 + (fromHexString (splitAddress 3));
  netdevDependencies = map (name: netnsCfg.netdevs."vrf-${name}".service) (attrNames cfg.metadata);
in
{
  options.services.enthalpy.bird = {
    enable = mkEnableOption "bird integration" // {
      default = true;
    };
    prefixes = mkOption {
      type = types.listOf types.str;
      default = [ "2a0e:aa07:e210::/44" ];
      readOnly = true;
      description = ''
        List of prefixes that this autonomous system is allowed to announce.
      '';
    };
    transit = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        List of transit network entities in the enthalpy network.
      '';
    };
  };

  config = mkIf (cfg.enable && cfg.bird.enable) {
    systemd.services.netns-enthalpy-bird = {
      requires = netdevDependencies;
      after = netdevDependencies;
    };

    networking.netns.enthalpy = {
      services.bird = {
        enable = true;
        config = ''
          router id ${toString routerId};

          protocol device {
            scan time 5;
          }

          ipv6 sadr table sadr6;

          protocol kernel {
            kernel table ${toString netnsCfg.routingTables.vrf-local};
            ipv6 sadr {
              export all;
              import none;
            };
            metric 512;
          }

          function is_safe_prefix() -> bool {
            return net.dst.len <= 60;
          }

          function is_enthalpy_prefix() -> bool {
            return net.dst ~ [${cfg.network}+];
          }

          function is_rebmit_prefix() -> bool {
            return net.dst ~ [${concatMapStringsSep ",\n" (p: "${p}+") cfg.bird.prefixes}];
          }

          protocol static {
            ipv6 sadr;
            route ${cfg.prefix} from ::/0 unreachable;
          }

          ${concatMapStringsSep "\n" (name: ''
            function is_entity_${name}_prefix() -> bool {
              return net.dst ~ [${concatMapStringsSep ",\n" (p: "${p}+") cfg.metadata."${name}".prefixes}];
            }

            protocol babel entity_${name} {
              vrf "vrf-${name}";
              ipv6 sadr {
                export filter {
                  if !is_safe_prefix() then reject;
                  accept;
                };
                import filter {
                  if !is_safe_prefix() then reject;
                  ${optionalString (name != cfg.entity && !builtins.elem name cfg.bird.transit) ''
                    if !is_entity_${name}_prefix() then reject;
                  ''}
                  accept;
                };
              };
              randomize router id;
              interface "enta*" {
                type tunnel;
                link quality etx;
                rxcost 32;
                rtt cost 1024;
                rtt max 1024 ms;
                rx buffer 2000;
              };
            }
          '') (attrNames cfg.metadata)}
        '';
      };
    };
  };
}
