{
  profiles,
  lib,
  config,
  hostData,
  mylib,
  ...
}:
{
  imports = with profiles; [
    services.enthalpy.customer-dualstack
  ];

  services.enthalpy = {
    ipsec.interfaces = [ "enp2s0" ];
    clat.segment = lib.singleton "fde3:3be3:a244:f876::2";
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
          DHCPServer = "yes";
          IPv6SendRA = "yes";
          IPv6PrivacyExtensions = true;
          IPv6AcceptRA = "no";
          KeepConfiguration = true;
        };
        dhcpServerConfig = {
          ServerAddress = "100.64.0.1/20";
          EmitDNS = true;
          DNS = "10.10.0.21";
        };
        ipv6Prefixes = lib.singleton {
          Prefix = "fdce:2962:c3c1:130c::/64";
          Assign = true;
        };
      };
      "30-enp2s0" = {
        matchConfig.Name = "enp2s0";
        networkConfig = {
          DHCP = "yes";
          IPv6AcceptRA = true;
          IPv6PrivacyExtensions = true;
          KeepConfiguration = true;
        };
        dhcpV4Config.RouteMetric = 1024;
        dhcpV6Config.RouteMetric = 1024;
        ipv6AcceptRAConfig.RouteMetric = 1024;
      };
    };
  };

  networking.nftables.tables.nat = {
    family = "inet";
    content = ''
      chain input {
        type filter hook input priority mangle; policy accept;
        iifname enp2s0 tcp dport { http, https } counter drop
        iifname enp2s0 udp dport { http, https } counter drop
      }

      chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;
        oifname enp2s0 counter masquerade
      }
    '';
  };

  sops.secrets."wireguard/reimu-aston/private-key" = {
    sopsFile = config.sops.secretFiles.get "hosts/flandre-m5p.yaml";
  };

  sops.secrets."wireguard/reimu-aston/preshared-key" = {
    sopsFile = config.sops.secretFiles.get "hosts/flandre-m5p.yaml";
  };

  networking.wireguard = {
    enable = true;
    interfaces = {
      reimu-aston = {
        privateKeyFile = config.sops.secrets."wireguard/reimu-aston/private-key".path;
        interfaceNamespace = "enthalpy";
        listenPort = config.networking.ports.enthalpy-wireguard-reimu-aston;
        peers = lib.singleton {
          publicKey = "Phf1usg7i2vW5gawA1C44ZIydCFFCUqyP01w9j4/bEY=";
          presharedKeyFile = config.sops.secrets."wireguard/reimu-aston/preshared-key".path;
          allowedIPs = [
            "172.16.0.1/32"
            "${mylib.network.cidr.host 1 (mylib.network.cidr.subnet 4 15 hostData.enthalpy_node_prefix)}/128"
          ];
        };
      };
    };
  };

  networking.netns.enthalpy = {
    enableIPv4Forwarding = lib.mkForce true;
    nftables = {
      enable = true;
      tables.wireguard-reimu-aston = {
        family = "ip";
        content = ''
          chain postrouting {
            type nat hook postrouting priority srcnat; policy accept;
            iifname reimu-aston oifname clat counter masquerade
          }
        '';
      };
    };
  };
}
