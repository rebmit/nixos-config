{ config, lib, ... }:
with lib;
let
  cfg = config.ports;
  noCollision = l: length (unique l) == length l;
in
{
  options.ports = mkOption {
    type = with types; attrsOf port;
    default = {
      # standard ports
      ssh = 22;
      smtp = 25;
      dns = 53;
      http = 80;
      https = 443;
      smtp-tls = 465;
      smtp-submission = 587;
      imap-tls = 993;
      socks = 1080;
      ssh-alt = 2222;

      # local ports
      ntfy = 4000;
      keycloak = 4010;
      miniflux = 4020;
      matrix-synapse = 4030;
      heisenbridge = 4031;
      mautrix-telegram = 4032;
      rspamd-controller = 4040;
      rspamd-redis = 4041;
      caddy-admin = 4050;
      prometheus = 4060;
      prometheus-alertmanager = 4061;
      prometheus-node-exporter = 4070;
      prometheus-blackbox-exporter = 4071;
      vaultwarden = 4080;
      forgejo = 4090;
      netns-enthalpy-proxy = 4100;

      # public ports
      ipsec-nat-traversal = 14000;
    };
    readOnly = true;
    description = ''
      A mapping of network ports, each identified by a unique name.
    '';
  };

  config = {
    assertions = singleton {
      assertion = noCollision (attrValues cfg);
      message = "port collision";
    };
  };
}
