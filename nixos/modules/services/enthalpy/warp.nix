# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/3b03efb676ea602575c916b2b8bc9d9cd13b0d85/modules/gravity/default.nix (MIT License)
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
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.lists) singleton;
  inherit (mylib.network) cidr;

  cfg = config.services.enthalpy;
  netnsCfg = config.networking.netns.enthalpy;
in
{
  options.services.enthalpy.warp = {
    enable = mkEnableOption "warp integration" // {
      default = cfg.bird.exit.enable;
    };
    prefixes = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        List of prefixes that are routed to warp by default.
      '';
    };
  };

  config = mkIf (cfg.enable && cfg.warp.enable) {
    systemd.services.cloudflare-warp = mkMerge [
      netnsCfg.config
      {
        path = with pkgs; [
          gawk
          wgcf
          wireguard-tools
          iproute2
        ];
        preStart = ''
          if [ ! -f $STATE_DIRECTORY/wgcf-account.toml ]; then
            wgcf register --accept-tos --config $STATE_DIRECTORY/wgcf-account.toml
          fi
          if [ ! -f $STATE_DIRECTORY/wgcf-profile.conf ]; then
            wgcf generate --config $STATE_DIRECTORY/wgcf-account.toml --profile $STATE_DIRECTORY/wgcf-profile.conf
          fi
          sed '/^Address/d; /^DNS/d; /^MTU/d' $STATE_DIRECTORY/wgcf-profile.conf > $STATE_DIRECTORY/wg.conf
          sed '/^Address/!d' $STATE_DIRECTORY/wgcf-profile.conf > $STATE_DIRECTORY/address.conf
        '';
        script = ''
          ip link add warp mtu 1280 type wireguard
          ip link set warp vrf vrf-${cfg.entity}
          wg setconf warp $STATE_DIRECTORY/wg.conf
          awk -F'[ =,]' '/^Address/ {for (i=2; i<=NF; i++) if ($i ~ /^[0-9]/) print $i}' $STATE_DIRECTORY/address.conf | xargs -I {} ip addr add {} dev warp
          ip link set warp up
        '';
        preStop = ''
          ip link del warp
        '';
        serviceConfig = mylib.misc.serviceHardened // {
          Type = "oneshot";
          RemainAfterExit = true;
          StateDirectory = "warp";
          User = "cloudflare-warp";
          CapabilityBoundingSet = [
            "CAP_NET_ADMIN"
            "CAP_NET_BIND_SERVICE"
          ];
          AmbientCapabilities = [
            "CAP_NET_ADMIN"
            "CAP_NET_BIND_SERVICE"
          ];
          RestrictAddressFamilies = [
            "AF_UNIX"
            "AF_INET"
            "AF_INET6"
            "AF_NETLINK"
          ];
        };
      }
    ];

    users.users.cloudflare-warp = {
      group = "cloudflare-warp";
      isSystemUser = true;
    };

    users.groups.cloudflare-warp = { };

    networking.netns.enthalpy = {
      nftables.tables.warp = {
        family = "ip6";
        content = ''
          chain forward {
            type filter hook forward priority filter; policy accept;
            iifname warp tcp flags syn tcp option maxseg size set 1200
            oifname warp tcp flags syn tcp option maxseg size set 1200
          }

          chain postrouting {
            type nat hook postrouting priority srcnat; policy accept;
            oifname warp counter masquerade
          }
        '';
      };

      interfaces.warp = {
        routes =
          singleton {
            cidr = "::/0";
            table = netnsCfg.routingTables.warp;
          }
          ++ map (p: {
            cidr = p;
            table = netnsCfg.routingTables.vrf-local;
            extraOptions.from = cfg.network;
          }) cfg.warp.prefixes;
        netdevDependencies = [ "cloudflare-warp.service" ];
      };
    };

    services.enthalpy.srv6.actions = {
      "${cidr.host 3 cfg.srv6.prefix}" = "End.DT6 table ${toString netnsCfg.routingTables.warp}";
    };
  };
}
