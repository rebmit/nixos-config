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
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf mkAfter;
  inherit (lib.lists) singleton;
  inherit (lib.meta) getExe;
  inherit (mylib.network) cidr;

  cfg = config.services.enthalpy;
  netnsCfg = config.networking.netns.enthalpy;
in
{
  options.services.enthalpy.exit = {
    enable = mkEnableOption "exit node";
    plat.enable = mkEnableOption "the PLAT component of 464XLAT" // {
      default = true;
    };
  };

  config = mkIf (cfg.enable && cfg.exit.enable) {
    systemd.network.config.networkConfig = {
      IPv4Forwarding = true;
      IPv6Forwarding = true;
    };

    networking.nftables = mkIf cfg.exit.plat.enable {
      enable = true;
      tables.plat = {
        family = "ip";
        content = ''
          chain forward {
            type filter hook forward priority filter; policy accept;
            iifname plat tcp flags syn tcp option maxseg size set 1200
            oifname plat tcp flags syn tcp option maxseg size set 1200
          }
        '';
      };
    };

    systemd.network.networks."50-enthalpy" = {
      matchConfig.Name = "enthalpy";
      routes = mkIf (!config.services.bird.enable) (singleton {
        Destination = cfg.network;
        Gateway = "fe80::ff:fe00:1";
        GatewayOnLink = true;
      });
      routingPolicyRules = mkIf config.services.bird.enable (singleton {
        Priority = config.routingPolicyPriorities.enthalpy;
        Family = "ipv6";
        Table = config.routingTables.enthalpy;
      });
      linkConfig.RequiredForOnline = false;
    };

    systemd.services.plat = mkIf cfg.exit.plat.enable {
      serviceConfig = mylib.misc.serviceHardened // {
        Type = "forking";
        Restart = "on-failure";
        RestartSec = 5;
        DynamicUser = true;
        ExecStart = "${getExe pkgs.tayga} --config ${pkgs.writeText "tayga.conf" ''
          tun-device plat
          ipv6-addr fc00::
          ipv4-addr 100.127.0.1
          prefix 64:ff9b::/96
          dynamic-pool 100.127.0.0/16
        ''}";
        CapabilityBoundingSet = [ "CAP_NET_ADMIN" ];
        AmbientCapabilities = [ "CAP_NET_ADMIN" ];
        PrivateDevices = false;
      };
      after = [ "network-pre.target" ];
      wantedBy = [ "multi-user.target" ];
    };

    systemd.network.networks."70-plat" = mkIf cfg.exit.plat.enable {
      matchConfig.Name = "plat";
      routes = [
        {
          Destination = "64:ff9b::/96";
          Source = cfg.network;
        }
        { Destination = "100.127.0.0/16"; }
      ];
      networkConfig.LinkLocalAddressing = false;
      linkConfig.RequiredForOnline = false;
    };

    networking.netns.enthalpy = {
      netdevs.host = {
        kind = "veth";
        mtu = 1400;
        address = "02:00:00:00:00:01";
        vrf = "vrf-${cfg.entity}";
        extraArgs.peer = {
          name = "enthalpy";
          mtu = 1400;
          address = "02:00:00:00:00:02";
          netns = "/proc/1/ns/net";
        };
      };

      interfaces.host = {
        routes = singleton {
          cidr = "::/0";
          via = "fe80::ff:fe00:2";
          table = netnsCfg.routingTables.exit;
          from = cfg.network;
        };
        netdevDependencies = [ netnsCfg.netdevs.host.service ];
      };

      services.bird.config = mkAfter ''
        protocol static {
          ipv6 sadr;
          route ${cfg.network} from ::/0 unreachable;
          route ::/0 from ${cfg.network} via fe80::ff:fe00:2 dev "host";
        }

        protocol babel exit {
          vrf "vrf-${cfg.entity}";
          ipv6 sadr {
            export filter {
              if !is_safe_prefix() then reject;
              if !is_rebmit_prefix() then reject;
              accept;
            };
            import filter {
              if !is_safe_prefix() then reject;
              if is_enthalpy_prefix() then reject;
              accept;
            };
          };
          randomize router id;
          interface "host" {
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

    services.enthalpy.srv6 = {
      enable = true;
      actions = {
        "${cidr.host 2 cfg.srv6.prefix}" = "End.DT6 table ${toString netnsCfg.routingTables.exit}";
      };
    };

    services.bird.config = mkAfter ''
      ipv6 sadr table enthalpy6;

      protocol kernel {
        kernel table ${toString config.routingTables.enthalpy};
        ipv6 sadr {
          table enthalpy6;
          export all;
          import none;
        };
        metric 512;
      }

      protocol babel {
        ipv6 sadr {
          table enthalpy6;
          export all;
          import all;
        };
        randomize router id;
        interface "enthalpy" {
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
}
