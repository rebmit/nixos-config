{ profiles, hostData, ... }:
{
  imports = with profiles; [
    services.enthalpy.customer
  ];

  services.enthalpy.ipsec.interfaces = [ "ens18" ];

  systemd.network = {
    enable = true;
    wait-online.anyInterface = true;
    networks = {
      "30-ens18" = {
        matchConfig.Name = "ens18";
        networkConfig = {
          Address = hostData.endpoints;
          DHCP = false;
          IPv6AcceptRA = false;
        };
        routes = [
          { Destination = "203.34.137.1"; }
          { Destination = "2a0d:f302:137::1"; }
          { Gateway = "203.34.137.1"; }
          { Gateway = "2a0d:f302:137::1"; }
        ];
        dhcpV4Config.RouteMetric = 1024;
        dhcpV6Config.RouteMetric = 1024;
        ipv6AcceptRAConfig.RouteMetric = 1024;
      };
    };
  };
}
