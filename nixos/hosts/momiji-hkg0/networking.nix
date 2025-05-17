{ profiles, host, ... }:
{
  imports = with profiles; [ services.enthalpy ];

  services.enthalpy = {
    ipsec.interfaces = [ "enp1s0" ];
    srv6.enable = true;
  };

  systemd.network = {
    enable = true;
    wait-online.anyInterface = true;
    networks = {
      "30-enp1s0" = {
        matchConfig.Name = "enp1s0";
        networkConfig = {
          Address = host.endpoints_v6;
          DHCP = "ipv4";
          IPv6AcceptRA = false;
          IPv6PrivacyExtensions = false;
          KeepConfiguration = true;
        };
        routes = [ { Gateway = "fe80::1"; } ];
        dhcpV4Config.RouteMetric = 1024;
        dhcpV6Config.RouteMetric = 1024;
        ipv6AcceptRAConfig.RouteMetric = 1024;
      };
    };
  };
}
