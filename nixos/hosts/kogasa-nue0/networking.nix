{ profiles, host, ... }:
{
  imports = with profiles; [ services.enthalpy ];

  services.enthalpy = {
    ipsec.interfaces = [ "ens3" ];
  };

  systemd.network = {
    enable = true;
    wait-online.anyInterface = true;
    networks = {
      "30-ens3" = {
        matchConfig.Name = "ens3";
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
