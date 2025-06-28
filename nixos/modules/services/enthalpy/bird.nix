# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/3b03efb676ea602575c916b2b8bc9d9cd13b0d85/modules/gravity/default.nix (MIT License)
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types;
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (lib.strings) concatMapStringsSep splitString;
  inherit (lib.trivial) fromHexString;
  inherit (lib.network) ipv6;

  cfg = config.services.enthalpy;

  splitAddress = idx: builtins.elemAt (splitString ":" (ipv6.fromString cfg.prefix).address) idx;
  routerId = (fromHexString (splitAddress 2)) * 65536 + (fromHexString (splitAddress 3));
in
{
  options.services.enthalpy.bird = {
    enable = mkEnableOption "bird integration" // {
      default = true;
    };
    prefixes = mkOption {
      type = types.listOf types.str;
      default = [
        "2a0e:aa07:e210::/48"
        "2a0e:aa07:e21c::/48"
        "2a0e:aa07:e21d::/48"
      ];
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
    networking.netns.enthalpy = {
      services.bird = {
        enable = true;
        package = pkgs.bird2-rebmit;
        config = ''
          router id ${toString routerId};

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
        '';
      };
    };
  };
}
