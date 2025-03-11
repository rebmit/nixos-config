{ profiles, ... }:
{
  imports = with profiles; [ services.enthalpy ];

  services.enthalpy-ng = {
    ipsec.interfaces = [ "enp1s0" ];
    bird.exit = {
      enable = true;
      kind = "transit";
    };
    plat.enable = true;
    srv6.enable = true;
  };

  networking.nftables.tables.nat = {
    family = "ip";
    content = ''
      chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;
        oifname enp1s0 counter masquerade
      }
    '';
  };

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
