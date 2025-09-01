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
    ipsec.interfaces = [ "enp0s1" ];
    clat = {
      enable = true;
      segment = singleton "2a0e:aa07:e21c:5866::3";
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
          iifname "enta*" ct state established,related counter accept
          iifname "enta*" ip6 saddr { fe80::/64, 2a0e:aa07:e21c::/47 } counter accept
          iifname "enta*" counter drop
        }

        chain output {
          type filter hook output priority filter; policy accept;
          oifname "enta*" ip6 daddr != { fe80::/64, 2a0e:aa07:e21c::/47 } \
            icmpv6 type time-exceeded counter drop
        }
      '';
    };
  };

  networking.netns.enthalpy.services.proxy = {
    enable = true;
    inbounds = singleton {
      netnsPath = "/proc/1/ns/net";
      listenAddress = "[::]";
      listenPort = config.ports.netns-enthalpy-proxy;
    };
  };

  networking.hosts = {
    "2404:6800:4003:c06::be" = [ "scholar.google.com" ];
  };

  systemd.network = {
    enable = true;
    wait-online.anyInterface = true;
    networks = {
      "30-enp0s1" = {
        matchConfig.Name = "enp0s1";
        networkConfig = {
          DHCP = "yes";
          IPv6AcceptRA = true;
          IPv6PrivacyExtensions = true;
        };
        dhcpV4Config.RouteMetric = 1024;
        dhcpV6Config.RouteMetric = 1024;
        ipv6AcceptRAConfig.RouteMetric = 1024;
      };
    };
  };
}
