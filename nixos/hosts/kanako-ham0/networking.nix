{ hostData, ... }:
{
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
      "30-enp6s18" = {
        matchConfig.Name = "enp6s18";
        networkConfig = {
          Address = hostData.endpoints;
          DHCP = false;
          IPv6AcceptRA = false;
        };
        routes = [
          { Destination = "91.108.80.1"; }
          { Gateway = "91.108.80.1"; }
        ];
        dhcpV4Config.RouteMetric = 1024;
        dhcpV6Config.RouteMetric = 1024;
        ipv6AcceptRAConfig.RouteMetric = 1024;
      };
    };
  };
}
