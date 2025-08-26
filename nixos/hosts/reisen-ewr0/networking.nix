{
  profiles,
  config,
  lib,
  ...
}:
{
  imports = with profiles; [ services.enthalpy ];

  services.enthalpy = {
    ipsec.interfaces = [ "enp1s0" ];
    exit.enable = true;
    srv6.enable = true;
  };

  networking.nftables.tables.nat4 = {
    family = "ip";
    content = ''
      chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;
        oifname enp1s0 counter masquerade
      }
    '';
  };

  networking.netns.enthalpy.services.bird.config = lib.mkAfter ''
    protocol static {
      ipv6 sadr;
      route 2a0a:4cc0:2000::/48 from ${config.services.enthalpy.network} via fe80::ff:fe00:2 dev "host";
    }
  '';

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
      "30-enp1s0" = {
        matchConfig.Name = "enp1s0";
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
