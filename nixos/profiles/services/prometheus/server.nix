{ config, lib, ... }:
let
  common = import ../../../../zones/common.nix;
  publicHosts = lib.filterAttrs (_name: value: value.endpoints != [ ]) common.hosts;
  targets = lib.mapAttrsToList (name: _value: "${name}.rebmit.link") publicHosts;
in
{
  sops.secrets."prometheus/password" = {
    sopsFile = config.sops.secretFiles.host;
    owner = config.systemd.services.prometheus.serviceConfig.User;
    restartUnits = [ "prometheus.service" ];
  };

  services.prometheus = {
    enable = true;
    webExternalUrl = "https://prometheus.rebmit.moe";
    listenAddress = "127.0.0.1";
    port = config.networking.ports.prometheus;
    retentionTime = "7d";
    globalConfig = {
      scrape_interval = "1m";
      evaluation_interval = "1m";
    };
    scrapeConfigs = [
      {
        job_name = "metrics";
        scheme = "https";
        metrics_path = "/metrics";
        basic_auth = {
          username = "prometheus";
          password_file = config.sops.secrets."prometheus/password".path;
        };
        static_configs = [ { inherit targets; } ];
      }
    ];
  };

  services.caddy.virtualHosts."prometheus.rebmit.moe" = {
    extraConfig = with config.services.prometheus; ''
      reverse_proxy ${listenAddress}:${toString port}
    '';
  };
}
