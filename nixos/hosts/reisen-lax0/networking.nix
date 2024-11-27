{ ... }:
{
  systemd.network = {
    enable = true;
    wait-online.anyInterface = true;
    networks = {
      "30-enp3s0" = {
        matchConfig.Name = "enp3s0";
        networkConfig = {
          DHCP = "yes";
          IPv6AcceptRA = true;
          IPv6PrivacyExtensions = false;
          KeepConfiguration = true;
        };
        dhcpV4Config.RouteMetric = 1024;
        dhcpV6Config.RouteMetric = 1024;
        ipv6AcceptRAConfig.RouteMetric = 1024;
      };
    };
  };
}
