{
  hostData,
  profiles,
  config,
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
    clat.segment = lib.singleton "2a0e:aa07:e21c:2546::2";
  };

  # TODO: remove test config
  services.enthalpy-ng = {
    enable = true;
    identifier = 3448;
    ipsec = {
      organization = hostData.enthalpy_node_organization;
      commonName = config.networking.hostName;
      endpoints = [
        {
          serialNumber = "0";
          addressFamily = "ip4";
        }
        {
          serialNumber = "1";
          addressFamily = "ip6";
        }
      ];
      privateKeyPath = config.sops.secrets."enthalpy_node_private_key_pem".path;
      registry = "https://git.rebmit.moe/rebmit/nixos-config/raw/branch/master/zones/registry.json";
    };
    plat.enable = true;
    srv6.enable = true;
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
