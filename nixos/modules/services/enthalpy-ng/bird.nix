# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/3b03efb676ea602575c916b2b8bc9d9cd13b0d85/modules/gravity/default.nix
{
  config,
  lib,
  ...
}:
let
  inherit (lib) types;
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (lib.strings) concatMapStringsSep optionalString;

  cfg = config.services.enthalpy-ng;
  netnsCfg = config.networking.netns-ng.enthalpy-ng;
in
{
  options.services.enthalpy-ng.bird = {
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
    exit = {
      enable = mkEnableOption "exit node";
      kind = mkOption {
        type = types.enum [
          "transit"
          "peer"
        ];
        default = "peer";
        description = ''
          Specifies the type of network this exit node connects to.
        '';
      };
    };
  };

  config = mkIf (cfg.enable && cfg.bird.enable) {
    networking.netns-ng.enthalpy-ng = {
      services.bird = {
        enable = true;
        config = ''
          router id ${toString cfg.identifier};

          protocol device {
            scan time 5;
          }

          ipv6 sadr table sadr6;

          protocol kernel {
            ipv6 sadr {
              export all;
              import none;
            };
            metric 512;
          }

          function is_safe_prefix() {
            return net.dst.len <= 60;
          }

          function is_enthalpy_prefix() {
            return net.dst ~ [${cfg.network}+];
          }

          function is_rebmit_prefix() {
            return net.dst ~ [${concatMapStringsSep ",\n" (p: "${p}+") cfg.bird.prefixes}];
          }

          protocol static {
            ipv6 sadr;
            route ${cfg.prefix} from ::/0 unreachable;
          }

          ${optionalString cfg.bird.exit.enable ''
            protocol static {
              ipv6 sadr;
              route ${cfg.network} from ::/0 unreachable;
              ${optionalString (cfg.bird.exit.kind == "transit") ''
                route ::/0 from ${cfg.network} via fe80::ff:fe00:2 dev "host";
              ''}
            }
          ''}

          protocol babel {
            ipv6 sadr {
              export filter {
                if !is_safe_prefix() then reject;
                accept;
              };
              import filter {
                if !is_safe_prefix() then reject;
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

          ${optionalString cfg.bird.exit.enable ''
            protocol babel {
              ipv6 sadr {
                export filter {
                  if !is_safe_prefix() then reject;
                  if !is_rebmit_prefix() then reject;
                  accept;
                };
                import filter {
                  if !is_safe_prefix() then reject;
                  if is_enthalpy_prefix() then reject;
                  accept;
                };
              };
              randomize router id;
              interface "host" {
                type wired;
                rx buffer 2000;
              };
            }
          ''}
        '';
      };

      netdevs.host = mkIf cfg.bird.exit.enable {
        kind = "veth";
        mtu = 1400;
        address = "02:00:00:00:00:01";
        extraArgs.peer = {
          name = "enthalpy";
          mtu = 1400;
          address = "02:00:00:00:00:02";
          netns = "/proc/1/ns/net";
        };
      };

      interfaces.host = mkIf cfg.bird.exit.enable {
        netdevDependencies = [ netnsCfg.netdevs.host.service ];
      };
    };

    systemd.network.networks."50-enthalpy" = mkIf cfg.bird.exit.enable {
      matchConfig.Name = "enthalpy";
      linkConfig.RequiredForOnline = false;
    };
  };
}
