{
  profiles,
  data,
  lib,
  ...
}:
{
  imports = with profiles; [
    services.enthalpy
  ];

  services.enthalpy = {
    ipsec.interfaces = [ "enp3s0" ];
    exit = {
      enable = true;
      prefix = [
        {
          type = "bird";
          destination = "::/0";
          source = data.enthalpy_network_prefix;
        }
      ];
    };
    srv6.enable = true;
    nat64.enable = true;
  };

  networking.nftables.tables.nat = {
    family = "inet";
    content = ''
      chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;
        oifname enp3s0 counter masquerade
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
      "30-enp3s0" = {
        matchConfig.Name = "enp3s0";
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
      "50-enthalpy" = {
        routes = lib.singleton {
          Destination = data.enthalpy_network_prefix;
          Gateway = "fe80::ff:fe00:0";
        };
      };
    };
  };
}
