{
  config,
  profiles,
  lib,
  ...
}:
{
  imports = with profiles; [
    services.enthalpy
  ];

  services.enthalpy = {
    ipsec = {
      interfaces = [ "wlan0" ];
      whitelist = [ "rebmit's edge network" ];
    };
    clat = {
      enable = true;
      segment = lib.singleton "fde3:3be3:a244:2676::2";
    };
    gost.enable = true;
  };

  systemd.services.nix-daemon = {
    serviceConfig = config.networking.netns.enthalpy.serviceConfig;
    after = [ "netns-enthalpy.service" ];
    requires = [ "netns-enthalpy.service" ];
  };

  systemd.services."user@${toString config.users.users.rebmit.uid}" = {
    overrideStrategy = "asDropin";
    serviceConfig = config.networking.netns.enthalpy.serviceConfig;
    after = [ "netns-enthalpy.service" ];
    requires = [ "netns-enthalpy.service" ];
  };

  systemd.network = {
    enable = true;
    wait-online.anyInterface = true;
    networks = {
      "30-enp3s0" = {
        matchConfig.Name = "enp3s0";
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
