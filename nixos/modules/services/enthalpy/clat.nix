# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/3b03efb676ea602575c916b2b8bc9d9cd13b0d85/nixos/mainframe/gravity.nix (MIT License)
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
  inherit (lib.strings) concatStringsSep;
  inherit (lib.lists) singleton;
  inherit (mylib.network) cidr;

  cfg = config.services.enthalpy;
  netnsCfg = config.networking.netns.enthalpy;
in
{
  options.services.enthalpy.clat = {
    enable = mkEnableOption "the CLAT component of 464XLAT";
    address = mkOption {
      type = types.str;
      default = cidr.host 2 cfg.prefix;
      description = ''
        IPv6 address used for CLAT as the mapped source address
        for outgoing packets from this node.
      '';
    };
    prefix = mkOption {
      type = types.str;
      default = "64:ff9b::/96";
      description = ''
        IPv6 prefix used for the PLAT component of 464XLAT.
      '';
    };
    segment = mkOption {
      type = types.listOf types.str;
      description = ''
        SRv6 segments to reach the PLAT gateway.
      '';
    };
  };

  config = mkIf (cfg.enable && cfg.clat.enable) {
    networking.netns.enthalpy = {
      services.tayga.clat = {
        ipv4Address = "192.0.0.1";
        prefix = cfg.clat.prefix;
        mappings."192.0.0.2" = cfg.clat.address;
      };

      interfaces.clat = {
        addresses = [ "192.0.0.2/32" ];
        routes = [
          {
            cidr = "${cfg.clat.address}/128";
          }
          {
            cidr = "0.0.0.0/0";
            extraOptions.src = "192.0.0.2";
          }
        ];
        netdevDependencies = [ netnsCfg.services.tayga.clat.service ];
      };

      interfaces.enthalpy = {
        routes = singleton {
          cidr = cfg.clat.prefix;
          from = "${cfg.clat.address}/128";
          extraOptions = {
            mtu = 1280;
            encap = "seg6 mode encap segs ${concatStringsSep "," cfg.clat.segment}";
          };
        };
      };
    };
  };
}
