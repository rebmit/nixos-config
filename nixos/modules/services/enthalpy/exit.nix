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
  staticPrefix = filter (p: p.type == "static") cfg.exit.prefix;
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
    systemd.network.networks."50-enthalpy" = {
      matchConfig.Name = "enthalpy";
      routes = singleton {
        Destination = cfg.network;
        Gateway = "fe80::ff:fe00:2";
      };
      linkConfig.RequiredForOnline = false;
    };

    services.enthalpy.bird.config = ''
      protocol static {
        ipv6 sadr;
        ${concatMapStringsSep "\n" (p: ''
          route ${p.destination} from ${p.source} via fe80::ff:fe00:1 dev "host";
        '') birdPrefix}
      }
    '';

    systemd.services.enthalpy-exit = {
      path = with pkgs; [
        coreutils
        iproute2
      ];
      script = ''
        ip link add enthalpy mtu 1400 address 02:00:00:00:00:01 type veth \
          peer host mtu 1400 address 02:00:00:00:00:02 netns enthalpy
        ip link set enthalpy up
        ip -n enthalpy link set host up
        ${concatMapStringsSep "\n" (
          p: "ip -n enthalpy -6 route add ${p.destination} from ${p.source} via fe80::ff:fe00:1 dev host"
        ) staticPrefix}
      '';
      preStop = ''
        ip link del enthalpy
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      after = [ "netns-enthalpy.service" ];
      partOf = [ "netns-enthalpy.service" ];
      wantedBy = [
        "multi-user.target"
        "netns-enthalpy.service"
      ];
    };
  };
}
