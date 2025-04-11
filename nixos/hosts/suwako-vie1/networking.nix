{ host, ... }:
{
  systemd.network = {
    enable = true;
    wait-online.anyInterface = true;
    networks = {
      "30-ens18" = {
        matchConfig.Name = "ens18";
        networkConfig = {
          Address = host.endpoints;
          DHCP = false;
          IPv6AcceptRA = false;
        };
        routes = [
          { Destination = "46.102.157.129"; }
          { Destination = "2a0d:f302:102::1"; }
          { Gateway = "46.102.157.129"; }
          { Gateway = "2a0d:f302:102::1"; }
        ];
        dhcpV4Config.RouteMetric = 1024;
        dhcpV6Config.RouteMetric = 1024;
        ipv6AcceptRAConfig.RouteMetric = 1024;
      };
    };
  };
}
