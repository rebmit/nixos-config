# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/3b03efb676ea602575c916b2b8bc9d9cd13b0d85/nixos/mainframe/gravity.nix
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

  cfg = config.services.enthalpy-ng;
  netnsCfg = config.networking.netns-ng.enthalpy-ng;
in
{
  options.services.enthalpy-ng.clat = {
    enable = mkEnableOption "464XLAT for IPv4 connectivity";
    prefix = mkOption {
      type = types.str;
      default = "64:ff9b::/96";
      description = ''
        IPv6 prefix used for NAT64 translation.
      '';
    };
    address = mkOption {
      type = types.str;
      default = cidr.host 2 cfg.prefix;
      description = ''
        IPv6 address used for 464XLAT as the mapped source address.
      '';
    };
    segment = mkOption {
      type = types.listOf types.str;
      description = ''
        SRv6 segments used for NAT64.
      '';
    };
  };

  config = mkIf (cfg.enable && cfg.clat.enable) {
    networking.netns-ng.enthalpy-ng = {
      services.tayga.clat = {
        ipv4Address = "192.0.0.1";
        prefix = cfg.clat.prefix;
        mapping = singleton {
          ipv4Address = "192.0.0.2";
          ipv6Address = cfg.clat.address;
        };
      };

      interfaces.clat = {
        addresses = [ "192.0.0.2/32" ];
        routes = [
          { cidr = "${cfg.clat.address}/128"; }
          {
            cidr = "0.0.0.0/0";
            extraOptions.src = "192.0.0.2";
          }
        ];
        netdevDependencies = [ netnsCfg.services.tayga.clat.service ];
      };

      interfaces.enthalpy = {
        routes = [
          {
            cidr = cfg.clat.prefix;
            extraOptions = {
              from = "${cfg.clat.address}/128";
              mtu = 1280;
              encap = "seg6 mode encap segs ${concatStringsSep "," cfg.clat.segment}";
            };
          }
        ];
      };
    };
  };
}
