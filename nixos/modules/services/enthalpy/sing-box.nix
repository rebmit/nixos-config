# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/3b03efb676ea602575c916b2b8bc9d9cd13b0d85/nixos/mainframe/gravity.nix
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
in
{
  options.services.enthalpy.sing-box = {
    enable = mkEnableOption "sing-box universal proxy platform";
    tableName = mkOption {
      type = types.str;
      default = "sing-box";
      readOnly = true;
      description = ''
        Routing table used for sing-box.
      '';
    };
    table = mkOption {
      type = types.int;
      default = config.networking.routingTables."${cfg.sing-box.tableName}";
      readOnly = true;
      description = ''
        Routing table ID associated with the sing-box routing table.
      '';
    };
    priority = mkOption {
      type = types.int;
      default = config.networking.routingPolicyPriorities."${cfg.sing-box.tableName}";
      readOnly = true;
      description = ''
        Routing priority assigned to the sing-box routing table.
      '';
    };
    fwmark = mkOption {
      type = types.int;
      default = config.networking.routingMarks."${cfg.sing-box.tableName}";
      readOnly = true;
      description = ''
        Firewall mark designated for the sing-box routing table.
      '';
    };
    port = mkOption {
      type = types.int;
      default = config.networking.ports.sing-box;
      readOnly = true;
      description = ''
        Port for the mixed proxy to listen on.
      '';
    };
    clat = {
      enable = mkEnableOption "464XLAT for IPv4 connectivity";
      address = mkOption {
        type = types.str;
        default = cidr.host 2 cfg.prefix;
        description = ''
          IPv6 address used for 464XLAT as the mapped source address.
        '';
      };
      segment = mkOption {
        type = types.listOf types.str;
        description = ''
          SRv6 segments used for NAT64.
        '';
      };
    };
  };

  config = mkIf (cfg.enable && cfg.sing-box.enable) (mkMerge [
    # IPv6
    {
      systemd.network.networks."50-enthalpy" = {
        routes = [
          {
            Destination = "::/0";
            Gateway = "fe80::ff:fe00:0";
            Table = cfg.sing-box.table;
            Metric = 1024;
          }
          {
            Destination = "::0/0";
            Type = "blackhole";
            Table = cfg.sing-box.table;
            Metric = 4096;
          }
        ];
        routingPolicyRules = lib.singleton {
          Family = "both";
          FirewallMark = cfg.sing-box.fwmark;
          Priority = cfg.sing-box.priority;
          Table = cfg.sing-box.table;
        };
      };

      services.sing-box = {
        enable = true;
        settings = {
          log = {
            level = "info";
          };
          dns = {
            servers = [
              {
                tag = "cloudflare";
                address = "https://[2606:4700:4700::1111]/dns-query";
                strategy = "prefer_ipv6";
              }
              {
                tag = "local";
                address = "local";
                strategy = "prefer_ipv4";
              }
            ];
            rules = [
              {
                geosite = [ "cn" ];
                server = "local";
              }
            ];
            final = "cloudflare";
          };
          inbounds = [
            {
              type = "mixed";
              tag = "inbound";
              listen = "127.0.0.1";
              listen_port = cfg.sing-box.port;
              sniff = true;
              sniff_override_destination = true;
            }
          ];
          outbounds = [
            {
              type = "direct";
              tag = "enthalpy";
              routing_mark = cfg.sing-box.fwmark;
              domain_strategy = "prefer_ipv6";
            }
            {
              type = "direct";
              tag = "direct";
            }
          ];
          route = {
            rules = [
              {
                geosite = [ "cn" ];
                geoip = [ "cn" ];
                ip_cidr = [ "10.0.0.0/8" ];
                outbound = "direct";
              }
            ];
            final = "enthalpy";
          };
        };
      };

      environment.systemPackages = with pkgs; [ gg ];

      environment.etc."ggconfig.toml".source = (pkgs.formats.toml { }).generate "ggconfig.toml" {
        allow_insecure = false;
        no_udp = false;
        node = "socks5://127.0.0.1:${toString cfg.sing-box.port}";
        proxy_private = false;
        test_node_before_use = false;
      };
    }

    # IPv4 (464XLAT)
    (mkIf cfg.sing-box.clat.enable {
      systemd.network.config = {
        networkConfig = {
          IPv6Forwarding = true;
          ManageForeignRoutes = false;
        };
      };

      systemd.network.networks."50-clat" = {
        name = "clat";
        linkConfig = {
          MTUBytes = "1400";
          RequiredForOnline = false;
        };
        addresses = singleton { Address = "192.0.0.2/32"; };
        routes = [
          {
            Destination = "0.0.0.0/0";
            Table = cfg.sing-box.table;
            PreferredSource = "192.0.0.2";
            Metric = 1024;
          }
          { Destination = cfg.sing-box.clat.address; }
        ];
      };

      services.enthalpy.exit.enable = true;
      services.enthalpy.exit.prefix = singleton "${cfg.sing-box.clat.address}/128";

      systemd.services.enthalpy-clatd = {
        path = with pkgs; [
          iproute2
          tayga
        ];
        script = ''
          ip r replace 64:ff9b::/96 from ${cfg.sing-box.clat.address} encap seg6 mode encap \
            segs ${concatStringsSep "," cfg.sing-box.clat.segment} dev ${cfg.interface} mtu 1280
          exec tayga -d --config ${pkgs.writeText "tayga.conf" ''
            tun-device clat
            prefix 64:ff9b::/96
            ipv4-addr 192.0.0.1
            map 192.0.0.2 ${cfg.sing-box.clat.address}
          ''}
        '';
        partOf = [ "enthalpy.service" ];
        after = [
          "enthalpy.service"
          "network.target"
        ];
        requires = [ "enthalpy.service" ];
        requiredBy = [ "enthalpy.service" ];
        wantedBy = [ "multi-user.target" ];
      };
    })
  ]);
}
