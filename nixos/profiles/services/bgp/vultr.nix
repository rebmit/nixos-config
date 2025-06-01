{ config, pkgs, ... }:
{
  services.bird = {
    enable = true;
    package = pkgs.bird2-rebmit;
    checkConfig = false;
    config = ''
      protocol device {
        scan time 5;
      }

      protocol static announce6 {
        ipv6;
        route 2a0e:aa07:e210::/48 unreachable;
        route 2a0e:aa07:e21c::/48 unreachable;
        route 2a0e:aa07:e21d::/48 unreachable;
      }

      protocol kernel kernel6 {
        ipv6 {
          export where proto = "announce6";
          import all;
        };
        learn;
      }

      include "${config.sops.secrets."bgp/vultr".path}";

      protocol bgp vultr6 {
        ipv6 {
          import none;
          export where proto = "announce6";
        };
        local as 212982;
        graceful restart on;
        multihop 2;
        neighbor 2001:19f0:ffff::1 as 64515;
        password VULTR_BGP_PASSWD;
      }
    '';
  };

  sops.secrets."bgp/vultr" = {
    sopsFile = config.sops.secretFiles.get "common.yaml";
    owner = config.systemd.services.bird.serviceConfig.User;
    reloadUnits = [ "bird.service" ];
  };
}
