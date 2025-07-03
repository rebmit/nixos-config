{
  profiles,
  config,
  lib,
  ...
}:
let
  inherit (lib.lists) singleton;
in
{
  imports = with profiles; [ services.enthalpy ];

  services.enthalpy = {
    ipsec.interfaces = [ "enp14s0" ];
    clat = {
      enable = true;
      segment = singleton "2a0e:aa07:e21c:2546::3";
    };
  };

  systemd.services.nix-daemon = config.networking.netns.enthalpy.config;
  systemd.services."user@${toString config.users.users.rebmit.uid}" =
    config.networking.netns.enthalpy.config
    // {
      overrideStrategy = "asDropin";
      restartIfChanged = false;
    };

  networking.netns.enthalpy.nftables.tables = {
    filter6 = {
      family = "ip6";
      content = ''
        chain input {
          type filter hook input priority filter; policy accept;
          icmpv6 type { nd-neighbor-solicit, nd-router-advert, nd-neighbor-advert } counter accept
          ip6 nexthdr icmpv6 ip6 saddr { fe80::/10, ff00::/8 } counter accept
          ip6 nexthdr icmpv6 ct state established,related counter accept
          ip6 nexthdr icmpv6 ip6 saddr 2a0e:aa07:e21c::/47 ct state new counter accept
          ip6 nexthdr icmpv6 counter drop
        }
      '';
    };
  };

  services.proxy = {
    enable = true;
    inbounds = singleton {
      netnsPath = config.networking.netns.enthalpy.netnsPath;
      listenPort = config.networking.netns.enthalpy.ports.proxy-init-netns;
    };
  };

  systemd.network = {
    enable = true;
    wait-online.anyInterface = true;
    networks = {
      "30-enp14s0" = {
        matchConfig.Name = "enp14s0";
        networkConfig = {
          DHCP = "yes";
          IPv6AcceptRA = true;
          IPv6PrivacyExtensions = true;
        };
        dhcpV4Config.RouteMetric = 1024;
        dhcpV6Config.RouteMetric = 1024;
        ipv6AcceptRAConfig.RouteMetric = 1024;
      };
      "40-wlan0" = {
        matchConfig.Name = "wlan0";
        networkConfig = {
          DHCP = "yes";
          IPv6AcceptRA = true;
          IPv6PrivacyExtensions = true;
        };
        dhcpV4Config.RouteMetric = 2048;
        dhcpV6Config.RouteMetric = 2048;
        ipv6AcceptRAConfig.RouteMetric = 2048;
      };
    };
  };
}
