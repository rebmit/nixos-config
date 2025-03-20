{
  profiles,
  config,
  lib,
  ...
}:
let
  inherit (lib.lists) singleton;
in
{
  imports = with profiles; [ services.enthalpy ];

  services.enthalpy = {
    ipsec.interfaces = [ "enp0s1" ];
    clat = {
      enable = true;
      segment = singleton "2a0e:aa07:e21c:2546::2";
    };
  };

  systemd.services.nix-daemon = config.networking.netns.enthalpy.config;
  systemd.services."user@${toString config.users.users.rebmit.uid}" =
    config.networking.netns.enthalpy.config
    // {
      overrideStrategy = "asDropin";
      restartIfChanged = false;
    };

  networking.netns.enthalpy.services.proxy = {
    enable = true;
    inbounds = singleton {
      netnsPath = "/proc/1/ns/net";
      listenAddress = "[::]";
      listenPort = config.ports.netns-enthalpy-proxy;
    };
  };

  systemd.network = {
    enable = true;
    wait-online.anyInterface = true;
    networks = {
      "30-enp0s1" = {
        matchConfig.Name = "enp0s1";
        networkConfig = {
          DHCP = "yes";
          IPv6AcceptRA = true;
          IPv6PrivacyExtensions = true;
        };
        dhcpV4Config.RouteMetric = 1024;
        dhcpV6Config.RouteMetric = 1024;
        ipv6AcceptRAConfig.RouteMetric = 1024;
      };
    };
  };
}
