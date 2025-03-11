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
      "eno1"
      "wlan0"
    ];
    clat = {
      enable = true;
      segment = singleton "2a0e:aa07:e21c:2546::2";
    };
  };

  systemd.services.nix-daemon = config.networking.netns-ng.enthalpy.config;
  systemd.services."user@${toString config.users.users.rebmit.uid}" =
    config.networking.netns-ng.enthalpy.config
    // {
      overrideStrategy = "asDropin";
      restartIfChanged = false;
    };

  services.proxy = {
    enable = true;
    inbounds = singleton {
      netnsPath = config.networking.netns-ng.enthalpy.netnsPath;
      listenPort = config.networking.netns-ng.enthalpy.misc.ports.proxy-init-netns;
    };
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
