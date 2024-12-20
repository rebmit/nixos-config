# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/3b03efb676ea602575c916b2b8bc9d9cd13b0d85/nixos/hcloud/iad1/prometheus.nix
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
    rules = lib.singleton (
      builtins.toJSON {
        groups = [
          {
            name = "metrics";
            rules = [
              {
                alert = "NodeDown";
                expr = ''up == 0'';
                for = "5m";
              }
              {
                alert = "OOM";
                expr = ''node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes < 0.1'';
              }
              {
                alert = "DiskFull";
                expr = ''node_filesystem_avail_bytes{mountpoint=~"/persist"} / node_filesystem_size_bytes < 0.1'';
              }
              {
                alert = "UnitFailed";
                expr = ''node_systemd_unit_state{state="failed"} == 1'';
              }
            ];
          }
        ];
      }
    );
  };

  services.caddy.virtualHosts."prometheus.rebmit.moe" = {
    extraConfig = with config.services.prometheus; ''
      reverse_proxy ${listenAddress}:${toString port}
    '';
  };
}
