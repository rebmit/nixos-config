{
  profiles,
  hostData,
  lib,
  ...
}:
{
  imports = with profiles; [
    services.enthalpy.customer
  ];

  services.enthalpy.ipsec.interfaces = [ "enp1s0" ];

  systemd.network = {
    enable = true;
    wait-online.anyInterface = true;
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
