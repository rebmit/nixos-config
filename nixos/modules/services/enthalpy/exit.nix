# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/3b03efb676ea602575c916b2b8bc9d9cd13b0d85/modules/gravity/default.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.enthalpy;
  birdPrefix = filter (p: p.type == "bird") cfg.exit.prefix;
  staticPrefix = subtractLists birdPrefix cfg.exit.prefix;
  staticRoutes = map (
    p: "${p.destination} from ${p.source} via fe80::ff:fe00:1 dev enthalpy"
  ) staticPrefix;
in
{
  options.services.enthalpy.exit = {
    enable = mkEnableOption "netns route leaking";
    prefix = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            type = mkOption {
              type = types.enum [
                "bird"
                "static"
              ];
              default = "static";
            };
            destination = mkOption { type = types.str; };
            source = mkOption {
              type = types.str;
              default = "::/0";
            };
          };
        }
      );
      default = [ ];
      description = ''
        Prefixes to be announced from the default netns to the enthalpy network.
      '';
    };
  };

  config = mkIf (cfg.enable && cfg.exit.enable) {
    services.enthalpy.bird.config = ''
      protocol static {
        ipv6 sadr;
        ${
          concatMapStringsSep "\n" (p: ''
            route ${p.destination} from ${p.source} via fe80::ff:fe00:1 dev "enthalpy";
          '') birdPrefix
        }
      }
    '';

    systemd.services.enthalpy-exit = mkIf (staticRoutes != [ ]) {
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = builtins.map (route: "${pkgs.iproute2}/bin/ip -6 route add ${route}") staticRoutes;
        ExecStop = builtins.map (route: "${pkgs.iproute2}/bin/ip -6 route del ${route}") staticRoutes;
      };
      after = [ "network.target" ];
      wants = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
    };

    services.enthalpy.services.enthalpy-exit = mkIf (staticRoutes != [ ]) { };
  };
}
