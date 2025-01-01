# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/3b03efb676ea602575c916b2b8bc9d9cd13b0d85/nixos/hcloud/iad1/prometheus.nix
{
  config,
  lib,
  pkgs,
  data,
  ...
}:
let
  cfg = config.services.prometheus;
  common = import ../../../../zones/common.nix;
  publicHosts = lib.filterAttrs (_name: value: value.endpoints != [ ]) common.hosts;
  targets = lib.mapAttrsToList (name: _value: "${name}.rebmit.link") publicHosts;
  primaryNameserver = "${common.primary}.rebmit.link";
  nameservers = map (ns: "${ns}.rebmit.link") common.nameservers;
  relabel_configs = [
    {
      source_labels = [ "__address__" ];
      target_label = "__param_target";
    }
    {
      source_labels = [ "__param_target" ];
      target_label = "instance";
    }
    {
      target_label = "__address__";
      replacement =
        with config.services.prometheus.exporters.blackbox;
        "${listenAddress}:${toString port}";
    }
  ];
in
{
  sops.secrets."prometheus/password" = {
    sopsFile = config.sops.secretFiles.host;
    owner = config.systemd.services.prometheus.serviceConfig.User;
    restartUnits = [ "prometheus.service" ];
  };

  sops.secrets."prometheus/alertmanager-ntfy" = {
    sopsFile = config.sops.secretFiles.host;
    restartUnits = [ "alertmanager.service" ];
  };

  services.prometheus = {
    enable = true;
    webExternalUrl = "https://prometheus.rebmit.workers.moe";
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
      {
        job_name = "caddy";
        scheme = "https";
        metrics_path = "/caddy";
        basic_auth = {
          username = "prometheus";
          password_file = config.sops.secrets."prometheus/password".path;
        };
        static_configs = [ { inherit targets; } ];
      }
      {
        job_name = "ping";
        scheme = "https";
        metrics_path = "/ping";
        basic_auth = {
          username = "prometheus";
          password_file = config.sops.secrets."prometheus/password".path;
        };
        static_configs = [ { inherit targets; } ];
      }
      {
        job_name = "dns";
        scheme = "http";
        metrics_path = "/probe";
        params = {
          module = [ "dns_soa" ];
        };
        static_configs = [ { targets = nameservers; } ];
        inherit relabel_configs;
      }
      {
        job_name = "http";
        scheme = "http";
        metrics_path = "/probe";
        params = {
          module = [ "http_2xx" ];
        };
        static_configs = [
          {
            targets = [
              "https://rebmit.moe"
              "https://chat.rebmit.moe"
              "https://id.rebmit.moe"
              "https://rss.rebmit.moe"
            ];
          }
        ];
        inherit relabel_configs;
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
              {
                alert = "ZoneStale";
                expr = ''probe_dns_serial{instance="${primaryNameserver}"} != ignoring(instance) group_right() probe_dns_serial'';
                for = "5m";
              }
            ];
          }
        ];
      }
    );
    alertmanagers = [
      {
        path_prefix = "/alert";
        static_configs = [
          {
            targets = [ "${cfg.alertmanager.listenAddress}:${builtins.toString cfg.alertmanager.port}" ];
          }
        ];
      }
    ];
    alertmanager = {
      enable = true;
      webExternalUrl = "https://${config.networking.fqdn}/alert";
      listenAddress = "127.0.0.1";
      port = config.networking.ports.prometheus-alertmanager;
      extraFlags = [ ''--cluster.listen-address=""'' ];
      configuration = {
        receivers = [
          {
            name = "ntfy";
            webhook_configs = [
              {
                url = "https://ntfy.rebmit.workers.moe/alert?tpl=yes&m=${lib.escapeURL ''
                  Alert {{.status}}
                  {{range .alerts}}-----{{range $k,$v := .labels}}
                  {{$k}}={{$v}}{{end}}
                  {{end}}
                ''}";
                http_config = {
                  basic_auth = {
                    username = "alertmanager";
                    password_file = "/run/credentials/alertmanager.service/alertmanager-ntfy";
                  };
                };
              }
            ];
          }
        ];
        route = {
          receiver = "ntfy";
        };
      };
    };
  };

  systemd.services.alertmanager.serviceConfig = {
    LoadCredential = [
      "alertmanager-ntfy:${config.sops.secrets."prometheus/alertmanager-ntfy".path}"
    ];
  };

  services.prometheus.exporters.blackbox = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = config.networking.ports.prometheus-blackbox-exporter;
    configFile = (pkgs.formats.yaml { }).generate "config.yml" {
      modules = {
        http_2xx = {
          prober = "http";
        };
        dns_soa = {
          prober = "dns";
          dns = {
            query_name = "rebmit.moe";
            query_type = "SOA";
          };
        };
      };
    };
  };

  sops.secrets."cloudflare_origin_prometheus_private_key" = {
    opentofu = {
      enable = true;
    };
    restartUnits = [ "caddy.service" ];
  };

  systemd.services.caddy.serviceConfig = {
    LoadCredential = [
      "cloudflare_aop_prometheus_ca_cert:${builtins.toFile "cloudflare_aop_ca_certificate" data.cloudflare_aop_ca_certificate}"
      "cloudflare_origin_prometheus_cert:${builtins.toFile "cloudflare_origin_prometheus_certificate" data.cloudflare_origin_prometheus_certificate}"
      "cloudflare_origin_prometheus_key:${
        config.sops.secrets."cloudflare_origin_prometheus_private_key".path
      }"
    ];
  };

  services.caddy.virtualHosts."prometheus.rebmit.workers.moe" =
    let
      credentialPath = "/run/credentials/caddy.service";
    in
    {
      extraConfig = with config.services.prometheus; ''
        tls ${credentialPath}/cloudflare_origin_prometheus_cert ${credentialPath}/cloudflare_origin_prometheus_key {
          client_auth {
            mode require_and_verify
            trust_pool file ${credentialPath}/cloudflare_aop_prometheus_ca_cert
          }
        }
        reverse_proxy ${listenAddress}:${toString port}
      '';
    };

  preservation.preserveAt."/persist".directories = [
    {
      directory = "/var/lib/prometheus2";
      mode = "-";
      user = "-";
      group = "-";
    }
    {
      directory = "/var/lib/private/alertmanager";
      mode = "-";
      user = "-";
      group = "-";
    }
  ];
}
