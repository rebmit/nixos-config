# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/3b03efb676ea602575c916b2b8bc9d9cd13b0d85/modules/metrics/default.nix (MIT License)
{ config, ... }:
{
  sops.secrets."prometheus/metrics" = {
    sopsFile = config.sops.secretFiles.get "common.yaml";
    restartUnits = [ "caddy.service" ];
  };

  systemd.services.caddy.serviceConfig = {
    EnvironmentFile = [ config.sops.secrets."prometheus/metrics".path ];
  };

  services.prometheus.exporters.node = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = config.ports.prometheus-node-exporter;
    enabledCollectors = [ "systemd" ];
    disabledCollectors = [ "arp" ];
  };

  services.caddy.virtualHosts."${config.networking.fqdn}" = {
    extraConfig = with config.services.prometheus.exporters.node; ''
      route /metrics {
        basic_auth {
          prometheus {$PROM_PASSWD}
        }
        reverse_proxy ${listenAddress}:${toString port}
      }

      route /caddy {
        basic_auth {
          prometheus {$PROM_PASSWD}
        }
        metrics
      }
    '';
  };
}
