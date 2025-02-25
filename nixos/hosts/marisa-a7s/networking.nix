{
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
    ipsec.interfaces = [
      "eno1"
      "wlan0"
    ];
    clat.segment = lib.singleton "2a0e:aa07:e21c:2546::2";
  };

  systemd.tmpfiles.settings = {
    "10-iwd" = {
      "/var/lib/iwd/ZJUWLAN-Secure.8021x".C.argument = config.sops.secrets."wireless/edu".path;
    };
  };

  sops.secrets."wireless/edu" = {
    sopsFile = config.sops.secretFiles.get "local.yaml";
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
