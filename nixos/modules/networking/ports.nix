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
      http = 80;
      https = 443;
      socks = 1080;
      ssh = 2222;

      # local ports
      enthalpy-gost = 3000;
      ntfy = 4000;
      keycloak = 4010;
      miniflux = 4020;
      matrix-synapse = 4030;
      heisenbridge = 4031;

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
