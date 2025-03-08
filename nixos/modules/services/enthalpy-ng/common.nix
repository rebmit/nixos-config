{
  config,
  lib,
  mylib,
  ...
}:
let
  inherit (lib) types;
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (mylib.network) cidr;

  cfg = config.services.enthalpy-ng;
  netnsCfg = config.networking.netns-ng.enthalpy-ng;
in
{
  options.services.enthalpy-ng = {
    enable = mkEnableOption "enthalpy overlay network, next generation";
    identifier = mkOption {
      type = types.int;
      description = ''
        Unique identifier of the node in the enthalpy network.
      '';
    };
    prefix = mkOption {
      type = types.str;
      default = "${cidr.subnet (60 - cidr.length cfg.network) cfg.identifier cfg.network}";
      readOnly = true;
      description = ''
        Prefix to be announced for the local node in the enthalpy network.
      '';
    };
    address = mkOption {
      type = types.str;
      default = "${cidr.host 1 cfg.prefix}/128";
      readOnly = true;
      description = ''
        Address to be added into the enthalpy network as source address.
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
    networking.netns-ng.enthalpy-ng = {
      sysctl = {
        "net.ipv6.conf.all.forwarding" = 1;
        "net.ipv6.conf.default.forwarding" = 1;
      };

      netdevs.enthalpy = {
        kind = "dummy";
      };

      interfaces.enthalpy = {
        addresses = [ cfg.address ];
        netdevDependencies = [ netnsCfg.netdevs.enthalpy.service ];
      };
    };
  };
}
