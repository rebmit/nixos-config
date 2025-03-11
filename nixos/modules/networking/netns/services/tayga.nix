{
  config,
  lib,
  pkgs,
  mylib,
  ...
}:
let
  inherit (lib) types;
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.modules) mkMerge mkIf;
  inherit (lib.attrsets)
    listToAttrs
    nameValuePair
    mapAttrsToList
    ;
  inherit (lib.strings) optionalString concatStringsSep;
  inherit (lib.lists) flatten;
  inherit (lib.meta) getExe;

  taygaOptions =
    netnsName:
    { name, ... }:
    {
      options = {
        enable = mkEnableOption "tayga network device" // {
          default = true;
        };
        ipv4Address = mkOption {
          type = types.str;
          default = "192.0.0.1";
          description = ''
            Tayga's IPv4 address. This setting is mandatory.
          '';
        };
        ipv6Address = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            Tayga's IPv6 address. This setting is optional if the NAT64
            prefix is specified, otherwise mandatory. It is also mandatory
            if the NAT64 prefix is 64:ff9b::/96 and ipv4Address is a
            RFC1918 address.
          '';
        };
        prefix = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            The NAT64 prefix. The IPv4 address space is mapped into the IPv6
            address space by prepending this prefix to the IPv4 address.
            Using a /96 prefix is recommended in most situations, but all
            lengths specified in RFC 6052 are supported.
          '';
        };
        dynamicPool = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            IPv4 address prefix allocated for dynamic IP assignment. This
            setting is optional.
          '';
        };
        mappings = mkOption {
          type = types.attrsOf types.str;
          default = { };
          description = ''
            Single-host mapping between IPv4 and IPv6 address. This setting
            is optional.
          '';
        };
        service = mkOption {
          type = types.str;
          default = "netns-${netnsName}-tayga-${name}.service";
          readOnly = true;
          description = ''
            Systemd service name for the tayga netdev configuration.
          '';
        };
      };
    };
in
{
  options.networking.netns = mkOption {
    type = types.attrsOf (
      types.submodule (
        { name, ... }:
        {
          options.services.tayga = mkOption {
            type = types.attrsOf (types.submodule (taygaOptions name));
            default = { };
            description = ''
              Userland stateless NAT64 implementation for Linux.
            '';
          };
        }
      )
    );
  };

  config = {
    systemd.services = listToAttrs (
      flatten (
        mapAttrsToList (
          name: cfg:
          mapAttrsToList (
            n: v:
            nameValuePair "netns-${name}-tayga-${n}" (
              mkIf (cfg.enable && v.enable) (mkMerge [
                cfg.config
                {
                  serviceConfig = mylib.misc.serviceHardened // {
                    Type = "forking";
                    Restart = "on-failure";
                    RestartSec = 5;
                    DynamicUser = true;
                    CapabilityBoundingSet = [ "CAP_NET_ADMIN" ];
                    AmbientCapabilities = [ "CAP_NET_ADMIN" ];
                    RestrictAddressFamilies = [
                      "AF_UNIX"
                      "AF_INET"
                      "AF_INET6"
                      "AF_NETLINK"
                    ];
                    PrivateDevices = false;
                    ExecStart = "${getExe pkgs.tayga} --config ${pkgs.writeText "tayga.conf" ''
                      tun-device ${n}
                      ipv4-addr ${v.ipv4Address}
                      ${optionalString (v.ipv6Address != null) "ipv6-addr ${v.ipv6Address}"}
                      ${optionalString (v.prefix != null) "prefix ${v.prefix}"}
                      ${optionalString (v.dynamicPool != null) "dynamic-pool ${v.dynamicPool}"}
                      ${concatStringsSep "\n" (mapAttrsToList (name: value: "map ${name} ${value}") v.mappings)}
                    ''}";
                  };
                }
              ])
            )
          ) cfg.services.tayga
        ) config.networking.netns
      )
    );
  };
}
