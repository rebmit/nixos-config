{
  profiles,
  hostData,
  lib,
  ...
}:
{
  imports = with profiles; [
    services.enthalpy.transit-dualstack
  ];

  services.enthalpy.ipsec.interfaces = [ "enp1s0" ];

  networking.nftables.tables.nat = {
    family = "inet";
    content = ''
      chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;
        oifname enp1s0 counter masquerade
      }
    '';
  };

  systemd.network = {
    enable = true;
    wait-online.anyInterface = true;
    config = {
      networkConfig = {
        IPv4Forwarding = true;
        IPv6Forwarding = true;
      };
    };
    networks = {
      "30-enp1s0" = {
        matchConfig.Name = "enp1s0";
        networkConfig = {
          DHCP = "ipv4";
          Address = hostData.endpoints_v6;
          IPv6AcceptRA = false;
        };
        routes = lib.singleton { Gateway = "fe80::1"; };
        dhcpV4Config.RouteMetric = 1024;
        dhcpV6Config.RouteMetric = 1024;
        ipv6AcceptRAConfig.RouteMetric = 1024;
      };
    };
  };
}
