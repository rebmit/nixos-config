{
  profiles,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkMerge mkForce;
  inherit (lib.strings) concatMapStringsSep;
  inherit (lib.lists) singleton;
in
{
  imports = with profiles; [ services.enthalpy ];

  services.enthalpy = {
    ipsec = {
      interfaces = [ "enp14s0" ];
      endpoints = lib.mkForce [
        {
          serialNumber = "1";
          addressFamily = "ip6";
        }
      ];
    };
    clat = {
      enable = true;
      segment = singleton "2a0e:aa07:e21c:2546::3";
    };
  };

  systemd.services.nix-daemon = {
    serviceConfig = mkMerge [
      config.netns.enthalpy.serviceConfig
      {
        ProtectSystem = mkForce false;
        BindPaths = mkForce [
          "/nix:/nix:rbind"
          "/var:/var:rbind"
          "${config.netns.enthalpy.rootDirectory}/run:/run:rbind"
          "/run/binfmt:/run/binfmt:rbind"
          # "/home:/home:rbind"
          # "/root:/root:rbind"
          "/tmp:/tmp:rbind" # TODO: remove and fix ${rootDirectory}/tmp to 1777
        ];
        BindReadOnlyPaths = mkForce [ ];
      }
    ];
    unitConfig = config.netns.enthalpy.unitConfig;
  };

  systemd.services."user@${toString config.users.users.rebmit.uid}" = {
    serviceConfig = mkMerge [
      config.netns.enthalpy.serviceConfig
      {
        ProtectSystem = mkForce false;
        BindPaths = mkForce [
          "/nix:/nix:rbind"
          "/var:/var:rbind"
          "${config.netns.enthalpy.rootDirectory}/run:/run:rbind"
          "/home:/home:rbind"
          "/root:/root:rbind"
          "/run/opengl-driver:/run/opengl-driver:rbind"
          "/run/dbus:/run/dbus:rbind"
          "/run/user:/run/user:rbind"
          "/run/pipewire:/run/pipewire:rbind"
          "/run/pulse:/run/pulse:rbind"
          "/run/systemd:/run/systemd:rbind"
          "/run/udev:/run/udev:rbind"
          "/run/wrappers:/run/wrappers:rbind"
          "/tmp:/tmp:rbind" # TODO: remove and fix ${rootDirectory}/tmp to 1777
        ];
        BindReadOnlyPaths = mkForce [
          "/bin:/bin:rbind"
          "/usr:/usr:rbind"
        ];
      }
    ];
    unitConfig = config.netns.enthalpy.unitConfig;
    overrideStrategy = "asDropin";
    restartIfChanged = false;
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

  services.proxy = {
    enable = true;
    inbounds = singleton {
      netnsPath = config.netns.enthalpy.netnsPath;
      listenPort = 3000;
    };
  };

  networking.hosts = {
    "2404:6800:4003:c06::be" = [ "scholar.google.com" ];
  };

  systemd.services.network-srv6 =
    let
      routes = [
        "0.0.0.0/0 encap seg6 mode encap segs 5f00::1 dev enp14s0 table wan0 mtu 1500 metric 512"
        "::/0      encap seg6 mode encap segs 5f00::1 dev enp14s0 table wan0 mtu 1500 metric 512"
        "0.0.0.0/0 encap seg6 mode encap segs 5f00::2 dev enp14s0 table wan1 mtu 1500 metric 512"
        "::/0      encap seg6 mode encap segs 5f00::2 dev enp14s0 table wan1 mtu 1500 metric 512"
      ];
    in
    {
      path = with pkgs; [
        iproute2
      ];
      script = concatMapStringsSep "\n" (r: "ip r add ${r}") routes;
      preStop = concatMapStringsSep "\n" (r: "ip r del ${r} || true") routes;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
    };

  systemd.network = {
    enable = true;
    wait-online.anyInterface = true;
    config = {
      routeTables = {
        wan0 = 300;
        wan1 = 301;
      };
    };
    networks = {
      "30-lo" = {
        matchConfig.Name = "lo";
        routes = [
          {
            Type = "blackhole";
            Destination = "0.0.0.0/0";
            Metric = 1024;
            Table = config.systemd.network.config.routeTables.wan0;
          }
          {
            Type = "blackhole";
            Destination = "::/0";
            Metric = 1024;
            Table = config.systemd.network.config.routeTables.wan0;
          }
          {
            Type = "blackhole";
            Destination = "0.0.0.0/0";
            Metric = 1024;
            Table = config.systemd.network.config.routeTables.wan1;
          }
          {
            Type = "blackhole";
            Destination = "::/0";
            Metric = 1024;
            Table = config.systemd.network.config.routeTables.wan1;
          }
        ];
        routingPolicyRules = [
          {
            Priority = 5000;
            Family = "both";
            FirewallMark = config.systemd.network.config.routeTables.wan0;
            Table = config.systemd.network.config.routeTables.wan0;
          }
          {
            Priority = 5000;
            Family = "both";
            FirewallMark = config.systemd.network.config.routeTables.wan1;
            Table = config.systemd.network.config.routeTables.wan1;
          }
        ];
      };
      "30-enp14s0" = {
        matchConfig.Name = "enp14s0";
        linkConfig.MTUBytes = 9000;
        networkConfig = {
          DHCP = "ipv4";
          IPv6AcceptRA = true;
          IPv6PrivacyExtensions = true;
          KeepConfiguration = true;
        };
        dhcpV4Config.RouteMetric = 1024;
        ipv6AcceptRAConfig.RouteMetric = 1024;
        routes = [
          {
            Destination = "5f00::/16";
            Gateway = "_ipv6ra";
            Table = config.systemd.network.config.routeTables.wan0;
          }
          {
            Destination = "5f00::/16";
            Gateway = "_ipv6ra";
            Table = config.systemd.network.config.routeTables.wan1;
          }
        ];
      };
      "40-wlan0" = {
        matchConfig.Name = "wlan0";
        networkConfig = {
          DHCP = "ipv4";
          IPv6AcceptRA = true;
          IPv6PrivacyExtensions = true;
          KeepConfiguration = true;
        };
        dhcpV4Config.RouteMetric = 2048;
        ipv6AcceptRAConfig.RouteMetric = 2048;
      };
    };
  };
}
