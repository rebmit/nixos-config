{
  profiles,
  host,
  config,
  lib,
  pkgs,
  mylib,
  ...
}:
let
  inherit (lib.lists) singleton;
  inherit (mylib.network) cidr;
in
{
  imports = with profiles; [ services.enthalpy ];

  services.enthalpy = {
    ipsec.interfaces = [ "wan0" ];
    clat = {
      enable = true;
      segment = singleton "2a0e:aa07:e21c:2546::3";
    };
    srv6.enable = true;
  };

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

  systemd.services.nix-daemon = config.networking.netns.enthalpy.config;

  systemd.tmpfiles.settings = {
    "10-iwd" = {
      "/var/lib/iwd/eduroam.8021x".C.argument = config.sops.secrets."wireless/eduroam".path;
      "/var/lib/iwd/ZJUWLAN-Secure.8021x".C.argument = config.sops.secrets."wireless/eduroam".path;
    };
  };

  sops.secrets."wireless/eduroam".sopsFile = config.sops.secretFiles.get "local.yaml";

  systemd.services.network-rules = {
    path = with pkgs; [
      iproute2
      coreutils
    ];
    script = ''
      ip -4 ru del pref 32766 || true
      ip -6 ru del pref 32766 || true
      ip -4 ru del pref 32767 || true
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    after = [ "network-pre.target" ];
    before = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
  };

  boot.kernel.sysctl = {
    "net.ipv4.tcp_l3mdev_accept" = 1;
    "net.ipv4.udp_l3mdev_accept" = 1;
    "net.ipv4.raw_l3mdev_accept" = 1;
  };

  systemd.network = {
    enable = true;
    wait-online.anyInterface = true;
    config = {
      networkConfig = {
        IPv4Forwarding = true;
        IPv6Forwarding = true;
      };
      routeTables = {
        exit = 200;
      };
    };
    links = {
      "20-lan0" = {
        matchConfig.Path = "pci-0000:01:00.0";
        linkConfig.Name = "lan0";
      };
      "20-wan0" = {
        matchConfig.Path = "pci-0000:02:00.0";
        linkConfig.Name = "wan0";
      };
      "20-wan1" = {
        matchConfig.Path = "pci-0000:03:00.0";
        linkConfig.Name = "wan1";
      };
    };
    netdevs = {
      "20-vrf0" = {
        netdevConfig = {
          Kind = "vrf";
          Name = "vrf0";
        };
        vrfConfig = {
          Table = 300;
        };
      };
      "20-vrf1" = {
        netdevConfig = {
          Kind = "vrf";
          Name = "vrf1";
        };
        vrfConfig = {
          Table = 301;
        };
      };
    };
    networks = {
      "30-lo" = {
        matchConfig.Name = "lo";
        routingPolicyRules = [
          {
            Priority = 500;
            Family = "both";
            Table = "main";
          }
          {
            Priority = 2000;
            Family = "both";
            L3MasterDevice = true;
            Type = "unreachable";
          }
          {
            Priority = 5000;
            Family = "both";
            Table = config.systemd.network.config.routeTables.exit;
          }
        ];
      };
      "30-lan0" = {
        matchConfig.Name = "lan0";
        linkConfig.MTUBytes = 9000;
        networkConfig = {
          DHCPServer = true;
          IPv6SendRA = true;
          IPv6AcceptRA = false;
          KeepConfiguration = true;
        };
        dhcpServerConfig = {
          ServerAddress = "100.72.45.1/24";
          UplinkInterface = "wan0";
          EmitDNS = true;
        };
        ipv6Prefixes = singleton {
          Prefix = cidr.subnet 4 15 host.enthalpy_node_prefix;
          Assign = true;
          Token = "static:::1";
        };
      };
      "30-vrf0" = {
        matchConfig.Name = "vrf0";
        routes = [
          {
            Destination = "0.0.0.0/0";
            PreferredSource = "100.72.45.1";
            Table = config.systemd.network.config.routeTables.exit;
          }
          {
            Destination = "::/0";
            Source = cidr.subnet 4 15 host.enthalpy_node_prefix;
            Table = config.systemd.network.config.routeTables.exit;
          }
        ];
      };
      "30-vrf1" = {
        matchConfig.Name = "vrf1";
      };
      "30-wan0" = {
        matchConfig.Name = "wan0";
        networkConfig = {
          DHCP = true;
          IPv6PrivacyExtensions = true;
          IPv6AcceptRA = true;
          VRF = [ "vrf0" ];
          KeepConfiguration = true;
        };
        dhcpV4Config.RouteMetric = 1024;
        ipv6AcceptRAConfig.RouteMetric = 1024;
      };
      "30-wan1" = {
        matchConfig.Name = "wan1";
        networkConfig = {
          DHCP = true;
          IPv6PrivacyExtensions = true;
          IPv6AcceptRA = true;
          VRF = [ "vrf1" ];
          KeepConfiguration = true;
        };
        dhcpV4Config.RouteMetric = 1024;
        ipv6AcceptRAConfig.RouteMetric = 1024;
      };
    };
  };

  networking.nftables.tables.nat = {
    family = "inet";
    content = ''
      chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;
        oifname { wan0, wan1 } counter masquerade
      }
    '';
  };
}
