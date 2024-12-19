{ config, lib, ... }:
with lib;
let
  cfg = config.networking.ports;
  noCollision = l: length (unique l) == length l;
in
{
  options.networking.ports = mkOption {
    type = with types; attrsOf port;
    default = {
      # standard ports
      smtp = 25;
      http = 80;
      https = 443;
      smtp-tls = 465;
      smtp-starttls = 587;
      imap-tls = 993;
      socks = 1080;
      ssh = 2222;

      # local ports
      enthalpy-gost = 3000;
      ntfy = 4000;
      keycloak = 4010;
      miniflux = 4020;
      matrix-synapse = 4030;
      heisenbridge = 4031;
      mautrix-telegram = 4032;
      rspamd-controller = 4040;
      rspamd-redis = 4041;

      # public ports
      enthalpy-ipsec = 13000;
      enthalpy-wireguard-reimu-aston = 13101;
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
