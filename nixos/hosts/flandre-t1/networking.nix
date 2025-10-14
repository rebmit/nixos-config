{
  profiles,
  config,
  lib,
  ...
}:
let
  inherit (lib.modules) mkMerge mkForce;
  inherit (lib.lists) singleton;
in
{
  imports = with profiles; [ services.enthalpy ];

  services.enthalpy = {
    ipsec = {
      interfaces = [ "enp3s0" ];
    };
    clat = {
      enable = true;
      segment = singleton "2a0e:aa07:e21c:2546::3";
    };
    srv6.enable = true;
  };

  netns.enthalpy.bindMounts = {
    "/nix".readOnly = false;
    "/var".readOnly = false;
  };

  systemd.services.nix-daemon = {
    serviceConfig = mkMerge [
      config.netns.enthalpy.serviceConfig
      { ProtectSystem = mkForce false; }
    ];
    unitConfig = config.netns.enthalpy.unitConfig;
  };

  netns.enthalpy.nftables.tables = {
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

  networking.hosts = {
    "100.72.45.1" = [
      "flandre-m5p.rebmit.link"
      "flandre-m5p.dyn.rebmit.link"
    ];
    "2a0e:aa07:e21c:a23f::1" = [
      "flandre-m5p.rebmit.link"
      "flandre-m5p.dyn.rebmit.link"
    ];
  };

  systemd.network = {
    enable = true;
    wait-online.anyInterface = true;
    networks = {
      "20-enp3s0" = {
        matchConfig.Name = "enp3s0";
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
