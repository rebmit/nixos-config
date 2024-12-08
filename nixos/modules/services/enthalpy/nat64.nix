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
  cfg = config.services.enthalpy;
in
{
  options.services.enthalpy.nat64 = {
    enable = mkEnableOption "NAT64";
    prefix = mkOption {
      type = types.str;
      default = "64:ff9b::/96";
      description = ''
        IPv6 prefix used for NAT64 translation in the network.
      '';
    };
    dynamicPool = mkOption {
      type = types.str;
      default = "100.127.0.0/16";
      description = ''
        IPv4 address prefix allocated for dynamic IP assignment.
      '';
    };
  };

  config = mkIf (cfg.enable && cfg.nat64.enable) {
    systemd.network.config.networkConfig.IPv6Forwarding = true;

    systemd.network.networks."70-nat64" = {
      matchConfig.Name = "nat64";
      routes = [
        {
          Destination = cfg.nat64.prefix;
          Table = config.networking.routingTables.nat64;
        }
        { Destination = cfg.nat64.dynamicPool; }
      ];
      networkConfig.LinkLocalAddressing = false;
      linkConfig.RequiredForOnline = false;
    };

    systemd.services.enthalpy-nat64 = {
      serviceConfig = mylib.misc.serviceHardened // {
        Type = "forking";
        Restart = "on-failure";
        RestartSec = 5;
        DynamicUser = true;
        ExecStart = "${pkgs.tayga}/bin/tayga --config ${pkgs.writeText "tayga.conf" ''
          tun-device nat64
          ipv6-addr fc00::
          ipv4-addr 100.127.0.1
          prefix ${cfg.nat64.prefix}
          dynamic-pool ${cfg.nat64.dynamicPool}
        ''}";
        CapabilityBoundingSet = [ "CAP_NET_ADMIN" ];
        AmbientCapabilities = [ "CAP_NET_ADMIN" ];
        PrivateDevices = false;
      };
      after = [ "netns-enthalpy.service" ];
      partOf = [ "netns-enthalpy.service" ];
      wantedBy = [
        "multi-user.target"
        "netns-enthalpy.service"
      ];
    };

    networking.nftables = {
      enable = true;
      tables.enthalpy4 = {
        family = "ip";
        content = ''
          chain forward {
            type filter hook forward priority 0;
            tcp flags syn tcp option maxseg size set 1200
          }
        '';
      };
    };
  };
}
