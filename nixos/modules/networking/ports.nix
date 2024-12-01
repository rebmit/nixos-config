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
      http = 80;
      https = 443;
      ssh = 2222;

      # enthalpy
      enthalpy-ipsec = 13000;
      enthalpy-gost = 1080;
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
