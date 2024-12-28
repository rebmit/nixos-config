{
  config,
  lib,
  ...
}:
let
  common = import ../../../../zones/common.nix;
  enthalpyHosts = lib.filterAttrs (_name: value: value.enthalpy_node_address != null) common.hosts;
  targets = lib.mapAttrsToList (name: _value: "${name}.enta.rebmit.link") enthalpyHosts;
in
{
  services.prometheus.exporters.ping = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = config.networking.ports.prometheus-ping-exporter;
    telemetryPath = "/ping";
    settings = {
      inherit targets;
    };
  };

  systemd.services.prometheus-ping-exporter = {
    inherit (config.networking.netns.enthalpy) serviceConfig;
    after = [ "netns-enthalpy.service" ];
    partOf = [ "netns-enthalpy.service" ];
    wantedBy = [ "netns-enthalpy.service" ];
  };

  networking.netns.init.forwardPorts = lib.singleton {
    protocol = "tcp";
    netns = "enthalpy";
    source = "127.0.0.1:${toString config.networking.ports.prometheus-ping-exporter}";
    target = "127.0.0.1:${toString config.networking.ports.prometheus-ping-exporter}";
  };

  services.caddy.virtualHosts."${config.networking.fqdn}" = {
    extraConfig = with config.services.prometheus.exporters.ping; ''
      route /ping {
        basic_auth {
          prometheus {$PROM_PASSWD}
        }
        reverse_proxy ${listenAddress}:${toString port}
      }
    '';
  };
}
