{
  config,
  lib,
  pkgs,
  mylib,
  ...
}:
let
  inherit (lib) types;
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (lib.meta) getExe;
  inherit (mylib.network) cidr;

  cfg = config.services.nat64;
in
{
  options.services.nat64 = {
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
    ipv4Address = mkOption {
      type = types.str;
      default = "${cidr.host 1 cfg.dynamicPool}";
      description = ''
        Tayga's IPv4 address.
      '';
    };
    ipv6Address = mkOption {
      type = types.str;
      default = "fc00::";
      description = ''
        Tayga's IPv6 address.
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.network.config.networkConfig.IPv6Forwarding = true;

    systemd.network.networks."70-nat64" = {
      matchConfig.Name = "nat64";
      routes = [
        {
          Destination = cfg.prefix;
          Table = config.networking.routingTables.nat64;
        }
        { Destination = cfg.dynamicPool; }
      ];
      networkConfig.LinkLocalAddressing = false;
      linkConfig.RequiredForOnline = false;
    };

    systemd.services.nat64 = {
      serviceConfig = mylib.misc.serviceHardened // {
        Type = "forking";
        Restart = "on-failure";
        RestartSec = 5;
        DynamicUser = true;
        ExecStart = "${getExe pkgs.tayga} --config ${pkgs.writeText "tayga.conf" ''
          tun-device nat64
          ipv4-addr ${cfg.ipv4Address}
          ipv6-addr ${cfg.ipv6Address}
          prefix ${cfg.prefix}
          dynamic-pool ${cfg.dynamicPool}
        ''}";
        CapabilityBoundingSet = [ "CAP_NET_ADMIN" ];
        AmbientCapabilities = [ "CAP_NET_ADMIN" ];
        PrivateDevices = false;
      };
      after = [ "network-pre.target" ];
      wantedBy = [ "multi-user.target" ];
    };

    networking.nftables = {
      enable = true;
      tables.nat64 = {
        family = "ip";
        content = ''
          chain forward {
            type filter hook forward priority 0;
            iifname "nat64" tcp flags syn tcp option maxseg size set 1200
            oifname "nat64" tcp flags syn tcp option maxseg size set 1200
          }
        '';
      };
    };
  };
}
