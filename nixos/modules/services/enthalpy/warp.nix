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
  warpNetnsCfg = config.networking.netns.warp;
in
{
  options.services.enthalpy.warp = {
    enable = mkEnableOption "warp integration" // {
      default = cfg.exit.enable;
    };
    prefixes = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        List of prefixes that are routed to warp by default.
      '';
    };
    plat.enable = mkEnableOption "the PLAT component of 464XLAT" // {
      default = true;
    };
  };

  config = mkIf (cfg.enable && cfg.warp.enable) {
    networking.netns.warp = {
      sysctl = {
        "net.ipv6.conf.all.forwarding" = 1;
        "net.ipv6.conf.default.forwarding" = 1;
        "net.ipv4.conf.all.forwarding" = 1;
        "net.ipv4.conf.default.forwarding" = 1;
      };

      nftables.tables.warp = {
        family = "inet";
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

      interfaces.enthalpy = {
        routes = singleton {
          cidr = cfg.network;
          via = "fe80::ff:fe00:1";
        };
        netdevDependencies = [ netnsCfg.netdevs.warp.service ];
      };

      services.tayga.plat = mkIf cfg.warp.plat.enable {
        ipv6Address = "fc00::";
        ipv4Address = "100.127.0.1";
        prefix = "64:ff9b::/96";
        dynamicPool = "100.127.0.0/16";
      };

      interfaces.plat = mkIf cfg.warp.plat.enable {
        routes = [
          { cidr = "100.127.0.0/16"; }
          {
            cidr = "64:ff9b::/96";
            extraOptions.from = cfg.network;
          }
        ];
        netdevDependencies = [ warpNetnsCfg.services.tayga.plat.service ];
      };

      interfaces.warp = {
        routes = [
          { cidr = "0.0.0.0/0"; }
          { cidr = "::/0"; }
        ];
        netdevDependencies = [ "cloudflare-warp-netdev.service" ];
      };
    };

    networking.netns.enthalpy = {
      netdevs.warp = {
        kind = "veth";
        mtu = 1400;
        address = "02:00:00:00:00:01";
        vrf = "vrf-${cfg.entity}";
        extraArgs.peer = {
          name = "enthalpy";
          mtu = 1400;
          address = "02:00:00:00:00:02";
          netns = warpNetnsCfg.netnsPath;
        };
      };

      interfaces.warp = {
        routes =
          singleton {
            cidr = "::/0";
            table = netnsCfg.routingTables.warp;
            via = "fe80::ff:fe00:2";
            extraOptions.from = cfg.network;
          }
          ++ map (p: {
            cidr = p;
            table = netnsCfg.routingTables.vrf-local;
            via = "fe80::ff:fe00:2";
            extraOptions.from = cfg.network;
          }) cfg.warp.prefixes;
        netdevDependencies = [ netnsCfg.netdevs.warp.service ];
      };
    };

    services.enthalpy.srv6.actions = {
      "${cidr.host 3 cfg.srv6.prefix}" = "End.DT6 table ${toString netnsCfg.routingTables.warp}";
    };

    systemd.services.cloudflare-warp-config = mkMerge [
      netnsCfg.config
      {
        path = with pkgs; [ wgcf ];
        script = ''
          if [ ! -f $STATE_DIRECTORY/wgcf-account.toml ]; then
            wgcf register --accept-tos --config $STATE_DIRECTORY/wgcf-account.toml
          fi
          if [ ! -f $STATE_DIRECTORY/wgcf-profile.conf ]; then
            wgcf generate --config $STATE_DIRECTORY/wgcf-account.toml --profile $STATE_DIRECTORY/wgcf-profile.conf
          fi
          sed '/^Address/d; /^DNS/d; /^MTU/d' $STATE_DIRECTORY/wgcf-profile.conf > $STATE_DIRECTORY/wg.conf
          sed '/^Address/!d' $STATE_DIRECTORY/wgcf-profile.conf > $STATE_DIRECTORY/address.conf
        '';
        serviceConfig = mylib.misc.serviceHardened // {
          Type = "oneshot";
          RemainAfterExit = true;
          StateDirectory = "warp";
          User = "cloudflare-warp";
          Restart = "on-failure";
          RestartSec = 5;
        };
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
      }
    ];

    systemd.services.cloudflare-warp-netdev = mkMerge [
      netnsCfg.config
      {
        path = with pkgs; [
          wireguard-tools
          iproute2
          gawk
        ];
        preStart = ''
          ip link del tmp-warp || true
          ip -n warp link del tmp-warp || true
          ip -n warp link del warp || true
        '';
        script = ''
          ip link add tmp-warp mtu 1280 type wireguard
          ip link set tmp-warp netns warp
          ip -n warp link set tmp-warp name warp
          ip netns exec warp wg setconf warp /var/lib/warp/wg.conf
          awk -F'[ =,]' '/^Address/ {for (i=2; i<=NF; i++) if ($i ~ /^[0-9]/) print $i}' \
            /var/lib/warp/address.conf | xargs -I {} ip -n warp addr add {} dev warp
          ip -n warp link set warp up
        '';
        preStop = ''
          ip -n warp link del warp
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          Restart = "on-failure";
          RestartSec = 5;
        };
        after = [
          "netns-warp.service"
          "cloudflare-warp-config.service"
        ];
        partOf = [
          "netns-warp.service"
          "cloudflare-warp-config.service"
        ];
        requires = [
          "netns-warp.service"
          "cloudflare-warp-config.service"
        ];
      }
    ];

    users.users.cloudflare-warp = {
      group = "cloudflare-warp";
      isSystemUser = true;
    };

    users.groups.cloudflare-warp = { };

    preservation.preserveAt."/persist".directories = [ "/var/lib/warp" ];
  };
}
