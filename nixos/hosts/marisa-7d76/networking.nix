{
  profiles,
  lib,
  ...
}:
{
  imports = with profiles; [
    services.enthalpy.customer-dualstack
    services.enthalpy.fw-proxy
  ];

  services.enthalpy = {
    ipsec.interfaces = [ "enp14s0" ];
    clat.segment = lib.singleton "fde3:3be3:a244:2546::2";
  };

  systemd.network = {
    enable = true;
    wait-online.anyInterface = true;
    networks = {
      "30-enp14s0" = {
        matchConfig.Name = "enp14s0";
        networkConfig = {
          DHCP = "yes";
          IPv6AcceptRA = true;
          IPv6PrivacyExtensions = true;
        };
        dhcpV4Config.RouteMetric = 1024;
        dhcpV6Config.RouteMetric = 1024;
        ipv6AcceptRAConfig.RouteMetric = 1024;
      };
      "40-wlan0" = {
        matchConfig.Name = "wlan0";
        networkConfig = {
          DHCP = "yes";
          IPv6AcceptRA = true;
          IPv6PrivacyExtensions = true;
        };
        dhcpV4Config.RouteMetric = 2048;
        dhcpV6Config.RouteMetric = 2048;
        ipv6AcceptRAConfig.RouteMetric = 2048;
      };
    };
  };
}
