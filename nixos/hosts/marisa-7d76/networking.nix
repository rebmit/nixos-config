{ profiles, lib, ... }:
{
  imports = with profiles; [
    services.enthalpy
  ];

  services.enthalpy = {
    users.rebmit = { };
    ipsec.interfaces = [ "enp14s0" ];
    clat = {
      enable = true;
      segment = lib.singleton "fde3:3be3:a244:2676::2";
    };
    gost.enable = true;
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
