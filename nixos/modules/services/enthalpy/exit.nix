# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/3b03efb676ea602575c916b2b8bc9d9cd13b0d85/modules/gravity/default.nix
{
  config,
  lib,
  pkgs,
  mylib,
  ...
}:
with lib;
let
  inherit (mylib.network) cidr;
  cfg = config.services.enthalpy;
  internalPrefix = filter (p: cidr.child p cfg.prefix) cfg.exit.prefix;
  externalPrefix = subtractLists internalPrefix cfg.exit.prefix;
in
{
  options.services.enthalpy.exit = {
    enable = mkEnableOption "netns route leaking";
    prefix = mkOption {
      type = types.listOf types.str;
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
            route ${p} from ${cfg.network} via fe80::ff:fe00:1 dev "enthalpy";
          '') externalPrefix
        }
      }
    '';

    systemd.services.enthalpy-exit =
      let
        routes = map (p: "${p} via fe80::ff:fe00:1 dev enthalpy") internalPrefix;
      in
      mkIf (routes != [ ]) {
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = builtins.map (route: "${pkgs.iproute2}/bin/ip -n ${cfg.netns} -6 r a ${route}") routes;
          ExecStop = builtins.map (route: "${pkgs.iproute2}/bin/ip -n ${cfg.netns} -6 r d ${route}") routes;
        };
        partOf = [ "enthalpy.service" ];
        after = [
          "enthalpy.service"
          "network-online.target"
        ];
        requires = [ "enthalpy.service" ];
        requiredBy = [ "enthalpy.service" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
      };
  };
}
