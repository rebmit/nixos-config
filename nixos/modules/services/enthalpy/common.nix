# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/882da114b98389121d98d909f115d49d9af6613e/modules/gravity.nix
{
  config,
  lib,
  mylib,
  ...
}:
with lib;
let
  inherit (mylib.network) cidr;
  cfg = config.services.enthalpy;
in
{
  options.services.enthalpy = {
    enable = mkEnableOption "enthalpy overlay network";
    prefix = mkOption {
      type = types.str;
      description = ''
        Prefix to be announced for the local node in the enthalpy network.
      '';
    };
    address = mkOption {
      type = types.str;
      default = cidr.host 1 cfg.prefix;
      description = ''
        Address to be added into the enthalpy network as source address.
      '';
    };
    netns = mkOption {
      type = types.str;
      default = "enthalpy";
      description = ''
        Name of the network namespace for enthalpy interfaces.
      '';
    };
    network = mkOption {
      type = types.str;
      description = ''
        Prefix of the enthalpy network.
      '';
    };
  };

  config = mkIf cfg.enable {
    networking.netns."${cfg.netns}" = {
      interface = cfg.netns;
      address = singleton "${cfg.address}/128";
      enableIPv4Forwarding = false;
      enableIPv6Forwarding = true;
    };
  };
}
