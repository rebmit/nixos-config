# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/3b03efb676ea602575c916b2b8bc9d9cd13b0d85/nixos/mainframe/gravity.nix
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
  inherit (lib.attrsets) mapAttrsToList;
  inherit (lib.strings) concatStringsSep;
  inherit (lib.meta) getExe;
  inherit (mylib.network) cidr;

  cfg = config.services.enthalpy-ng;
in
{
  options.services.enthalpy-ng.plat = {
    enable = mkEnableOption "the PLAT component of 464XLAT, NAT64 / SIIT-DC implementation";
    prefix = mkOption {
      type = types.str;
      default = "64:ff9b::/96";
      description = ''
        IPv6 prefix used for the PLAT component of 464XLAT.
      '';
    };
    dynamicPool = mkOption {
      type = types.nullOr types.str;
      default = "100.127.0.0/16";
      description = ''
        IPv4 address prefix allocated for dynamic IP assignment.
      '';
    };
    mappings = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = ''
        Single-host mapping between IPv4 and IPv6 address.
      '';
    };
  };

  config = mkIf (cfg.enable && cfg.plat.enable) {
    systemd.network.config.networkConfig.IPv6Forwarding = true;

    systemd.network.networks."70-plat" = {
      matchConfig.Name = "plat";
      routes = [
        {
          Destination = cfg.plat.prefix;
          Table = config.networking.routingTables.plat;
        }
        { Destination = cfg.plat.dynamicPool; }
      ];
      routingPolicyRules = [
        {
          Priority = config.networking.routingPolicyPriorities.plat;
          Family = "ipv6";
          Table = config.networking.routingTables.plat;
          From = cfg.network;
          To = cfg.plat.prefix;
        }
      ];
      networkConfig.LinkLocalAddressing = false;
      linkConfig.RequiredForOnline = false;
    };

    systemd.services.plat = {
      serviceConfig = mylib.misc.serviceHardened // {
        Type = "forking";
        Restart = "on-failure";
        RestartSec = 5;
        DynamicUser = true;
        ExecStart = "${getExe pkgs.tayga} --config ${pkgs.writeText "tayga.conf" ''
          tun-device plat
          ipv6-addr fc00::
          ipv4-addr ${cidr.host 1 cfg.plat.dynamicPool}
          prefix ${cfg.plat.prefix}
          dynamic-pool ${cfg.plat.dynamicPool}
          ${concatStringsSep "\n" (mapAttrsToList (name: value: "map ${name} ${value}") cfg.plat.mappings)}
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
      tables.plat = {
        family = "ip";
        content = ''
          chain forward {
            type filter hook forward priority 0;
            iifname "plat" tcp flags syn tcp option maxseg size set 1200
            oifname "plat" tcp flags syn tcp option maxseg size set 1200
          }
        '';
      };
    };
  };
}
