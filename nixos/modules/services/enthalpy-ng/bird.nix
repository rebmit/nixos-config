# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/3b03efb676ea602575c916b2b8bc9d9cd13b0d85/modules/gravity/default.nix
{
  config,
  lib,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;

  cfg = config.services.enthalpy-ng;
in
{
  options.services.enthalpy-ng.bird = {
    enable = mkEnableOption "bird for site-scope connectivity" // {
      default = true;
    };
  };

  config = mkIf (cfg.enable && cfg.bird.enable) {
    networking.netns-ng.enthalpy-ng = {
      services.bird = {
        enable = true;
        config = ''
          router id ${toString cfg.identifier};
          ipv6 sadr table sadr6;
          protocol device {
            scan time 5;
          }
          protocol kernel {
            ipv6 sadr {
              export all;
              import none;
            };
            metric 512;
          }
          protocol static {
            ipv6 sadr;
            route ${cfg.prefix} from ::/0 unreachable;
            route ${cfg.network} from ::/0 unreachable;
          };
          protocol babel {
            ipv6 sadr {
              export all;
              import all;
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
