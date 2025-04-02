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
      "30-ens18" = {
        matchConfig.Name = "ens18";
        networkConfig = {
          Address = hostData.endpoints;
          DHCP = false;
          IPv6AcceptRA = false;
        };
        routes = [
          { Destination = "91.108.80.1"; }
          { Gateway = "91.108.80.1"; }
          { Destination = "2a05:901:6::1"; }
          { Gateway = "2a05:901:6::1"; }
        ];
        dhcpV4Config.RouteMetric = 1024;
        dhcpV6Config.RouteMetric = 1024;
        ipv6AcceptRAConfig.RouteMetric = 1024;
      };
    };
  };
}
