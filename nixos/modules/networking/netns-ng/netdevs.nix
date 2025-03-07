{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types isAttrs;
  inherit (lib.options) mkOption;
  inherit (lib.modules) mkIf;
  inherit (lib.attrsets)
    listToAttrs
    nameValuePair
    mapAttrsToList
    ;
  inherit (lib.strings) optionalString concatStrings;
  inherit (lib.lists) flatten;

  netdevOptions =
    { ... }:
    {
      options = {
        kind = mkOption {
          type = types.str;
          description = ''
            Kind of the network device.
          '';
        };
        address = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            Specifies the MAC address to use for the device.
            Leave empty to use the default.
          '';
        };
        mtu = mkOption {
          type = types.nullOr types.int;
          default = null;
          description = ''
            The maximum transmission unit in bytes to set for the device.
            Leave empty to use the default.
          '';
        };
        extraArgs = mkOption {
          type = types.submodule {
            freeformType = (pkgs.formats.json { }).type;
          };
          default = { };
          description = ''
            Additional arguments for the netdev type. See {manpage}`ip-route(8)`
            manual page for the details.
          '';
        };
      };
    };

  attrsToString =
    attrs:
    concatStrings (
      mapAttrsToList (
        name: value:
        if isAttrs value then "${name} ${attrsToString value}" else "${name} ${toString value} "
      ) attrs
    );
in
{
  options.networking.netns-ng = mkOption {
    type = types.attrsOf (
      types.submodule (
        { ... }:
        {
          options = {
            netdevs = mkOption {
              type = types.attrsOf (types.submodule netdevOptions);
              default = { };
              description = ''
                Per-network namespace virtual network devices configuration.
              '';
            };
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
            nameValuePair "netns-${name}-netdev-${n}" (
              mkIf cfg.enable {
                path = with pkgs; [ iproute2 ];
                script = ''
                  ip link show dev "${n}" >/dev/null 2>&1 && ip link delete dev "${n}"
                  ip link add name "${n}" \
                    ${optionalString (v.address != null) "address ${v.address}"} \
                    ${optionalString (v.mtu != null) "mtu ${toString v.mtu}"} \
                    type "${v.kind}" ${attrsToString v.extraArgs}
                  ip link set dev "${n}" up
                '';
                postStop = ''
                  ip link delete dev "${n}" || true
                '';
                serviceConfig = {
                  Type = "oneshot";
                  RemainAfterExit = true;
                  NetworkNamespacePath = cfg.netnsPath;
                };
                after = [ "netns-${name}.service" ];
                partOf = [ "netns-${name}.service" ];
                wantedBy = [
                  "netns-${name}.service"
                  "multi-user.target"
                ];
              }
            )
          ) cfg.netdevs
        ) config.networking.netns-ng
      )
    );
  };
}
