# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/3b03efb676ea602575c916b2b8bc9d9cd13b0d85/nixos/hcloud/iad1/prometheus.nix (MIT License)
{
  config,
  lib,
  pkgs,
  data,
  ...
}:
let
  inherit (lib.lists) singleton;
  inherit (data.nameservers) primary secondary;

  cfg = config.services.prometheus;

  nameservers = [
    "ns1.he.net"
    "ns2.he.net"
    "reisen.any.rebmit.link"
  ] ++ map (ns: "${ns}.rebmit.link") (secondary ++ singleton primary);

  publicHosts = lib.filterAttrs (_name: value: value.endpoints != [ ]) data.hosts;
  targets = lib.mapAttrsToList (name: _value: "${name}.rebmit.link") publicHosts;
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
  sops.secrets."prom/password" = {
    sopsFile = config.sops.secretFiles.host;
    owner = config.systemd.services.prometheus.serviceConfig.User;
    restartUnits = [ "prometheus.service" ];
  };

  sops.secrets."prom/alertmanager-ntfy" = {
    sopsFile = config.sops.secretFiles.host;
    restartUnits = [ "alertmanager.service" ];
  };

  services.prometheus = {
    enable = true;
    webExternalUrl = "https://prom.rebmit.moe";
    listenAddress = "127.0.0.1";
    port = config.ports.prometheus;
    retentionTime = "7d";
    globalConfig = {
      scrape_interval = "1m";
      scrape_timeout = "30s";
      evaluation_interval = "1m";
    };
    scrapeConfigs = [
      {
        job_name = "metrics";
        scheme = "https";
        metrics_path = "/metrics";
        basic_auth = {
          username = "prometheus";
          password_file = config.sops.secrets."prom/password".path;
        };
        static_configs = [ { inherit targets; } ];
      }
      {
        job_name = "caddy";
        scheme = "https";
        metrics_path = "/caddy";
        basic_auth = {
          username = "prometheus";
          password_file = config.sops.secrets."prom/password".path;
        };
        static_configs = [ { inherit targets; } ];
      }
      {
        job_name = "dns/rebmit.moe";
        scheme = "http";
        metrics_path = "/probe";
        params = {
          module = [ "dns_soa/rebmit.moe" ];
        };
        static_configs = [ { targets = nameservers; } ];
        inherit relabel_configs;
      }
      {
        job_name = "dns/rebmit.link";
        scheme = "http";
        metrics_path = "/probe";
        params = {
          module = [ "dns_soa/rebmit.link" ];
        };
        static_configs = [ { targets = nameservers; } ];
        inherit relabel_configs;
      }
      {
        job_name = "http";
        scheme = "http";
        metrics_path = "/probe";
        params = {
          module = [ "http" ];
        };
        static_configs = [
          {
            targets = [
              "https://rebmit.moe/.well-known/matrix/server"
              "https://chat.rebmit.moe/_matrix/federation/v1/version"
              "https://git.rebmit.moe/api/v1/version"
              "https://idp.rebmit.moe/realms/rebmit/.well-known/openid-configuration"
              "https://rss.rebmit.moe/healthcheck"
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
                alert = "HttpFailure";
                expr = ''probe_http_status_code != 200'';
                for = "5m";
              }
              {
                alert = "ZoneStale";
                expr = ''probe_dns_serial{instance="${primary}.rebmit.link"} != ignoring(instance) group_right() probe_dns_serial'';
                for = "30m";
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
      port = config.ports.prometheus-alertmanager;
      extraFlags = [ ''--cluster.listen-address=""'' ];
      configuration = {
        receivers = [
          {
            name = "ntfy";
            webhook_configs = [
              {
                url = "https://push.workers.moe/alert?tpl=yes&m=${lib.escapeURL ''
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
      "alertmanager-ntfy:${config.sops.secrets."prom/alertmanager-ntfy".path}"
    ];
  };

  services.prometheus.exporters.blackbox = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = config.ports.prometheus-blackbox-exporter;
    configFile = (pkgs.formats.yaml { }).generate "config.yml" {
      modules = {
        http = {
          prober = "http";
        };
        "dns_soa/rebmit.moe" = {
          prober = "dns";
          dns = {
            query_name = "rebmit.moe";
            query_type = "SOA";
          };
        };
        "dns_soa/rebmit.link" = {
          prober = "dns";
          dns = {
            query_name = "rebmit.link";
            query_type = "SOA";
          };
        };
      };
    };
  };

  services.caddy.virtualHosts."prom.rebmit.moe" = {
    extraConfig = with config.services.prometheus; ''
      reverse_proxy ${listenAddress}:${toString port}
    '';
  };

  preservation.preserveAt."/persist".directories = [
    "/var/lib/prometheus2"
    "/var/lib/private/alertmanager"
  ];
}
