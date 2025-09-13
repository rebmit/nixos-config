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
    ipsec.interfaces = [
      "enp3s0"
      "wlan0"
    ];
    clat = {
      enable = true;
      segment = singleton "2a0e:aa07:e21c:2546::3";
    };
    srv6.enable = true;
  };

  systemd.services.nix-daemon = config.networking.netns.enthalpy.config;

  networking.netns.enthalpy.nftables.tables = {
    filter6 = {
      family = "ip6";
      content = ''
        chain input {
          type filter hook input priority filter; policy accept;
          iifname "enta*" ct state established,related counter accept
          iifname "enta*" ip6 saddr { fe80::/64, 2a0e:aa07:e21c::/47 } counter accept
          iifname "enta*" counter drop
        }

        chain output {
          type filter hook output priority filter; policy accept;
          oifname "enta*" ip6 daddr != { fe80::/64, 2a0e:aa07:e21c::/47 } \
            icmpv6 type time-exceeded counter drop
        }
      '';
    };
  };

  systemd.tmpfiles.settings = {
    "10-iwd" = {
      "/var/lib/iwd/eduroam.8021x".C.argument = config.sops.secrets."wireless/eduroam".path;
      "/var/lib/iwd/ZJUWLAN-Secure.8021x".C.argument = config.sops.secrets."wireless/eduroam".path;
    };
  };

  sops.secrets."wireless/eduroam".sopsFile = config.sops.secretFiles.get "local.yaml";

  networking.hosts = {
    "100.64.0.1" = [ "flandre-m5p.dyn.rebmit.link" ];
  };

  systemd.network = {
    enable = true;
    wait-online.anyInterface = true;
    networks = {
      "30-enp3s0" = {
        matchConfig.Name = "enp3s0";
        networkConfig = {
          DHCP = "ipv4";
          IPv6AcceptRA = true;
          IPv6PrivacyExtensions = true;
          KeepConfiguration = true;
        };
        dhcpV4Config = {
          UseDNS = false;
          UseGateway = false;
          RouteMetric = 2048;
        };
        ipv6AcceptRAConfig = {
          UseDNS = false;
          UseGateway = false;
          RouteMetric = 2048;
        };
      };
      "30-wlan0" = {
        matchConfig.Name = "wlan0";
        networkConfig = {
          DHCP = "ipv4";
          IPv6AcceptRA = true;
          IPv6PrivacyExtensions = true;
          KeepConfiguration = true;
        };
        dhcpV4Config.RouteMetric = 1024;
        ipv6AcceptRAConfig.RouteMetric = 1024;
      };
    };
  };
}
