# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/3b03efb676ea602575c916b2b8bc9d9cd13b0d85/modules/gravity/default.nix
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

  cfg = config.services.enthalpy;
  netnsCfg = config.networking.netns.enthalpy;
in
{
  options.services.enthalpy = {
    enable = mkEnableOption "enthalpy overlay network, next generation";
    identifier = mkOption {
      type = types.int;
      description = ''
        Unique identifier of the node in the enthalpy network.
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
    prefix = mkOption {
      type = types.str;
      default = "${cidr.subnet (60 - cidr.length cfg.network) cfg.identifier cfg.network}";
      readOnly = true;
      description = ''
        Prefix to be announced for the local node in the enthalpy network.
      '';
    };
    network = mkOption {
      type = types.str;
      default = "2a0e:aa07:e21c::/48";
      readOnly = true;
      description = ''
        Prefix of the enthalpy network.
      '';
    };
  };

  config = mkIf cfg.enable {
    boot.kernelModules = [ "vrf" ];

    networking.netns.enthalpy = {
      sysctl = {
        "net.ipv6.conf.all.forwarding" = 1;
        "net.ipv6.conf.default.forwarding" = 1;

        # https://www.kernel.org/doc/html/latest/networking/vrf.html#applications
        "net.vrf.strict_mode" = 1;
        "net.ipv4.tcp_l3mdev_accept" = 0;
        "net.ipv4.udp_l3mdev_accept" = 0;
        "net.ipv4.raw_l3mdev_accept" = 0;
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
