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
  inherit (lib.strings) concatStrings concatMapStrings optionalString;
  inherit (lib.lists) flatten;

  routeOptions =
    { ... }:
    {
      options = {
        cidr = mkOption {
          type = types.str;
          description = ''
            Address block of the network in CIDR representation.
          '';
        };
        type = mkOption {
          type = types.nullOr (
            types.enum [
              "unicast"
              "local"
              "broadcast"
              "multicast"
            ]
          );
          default = null;
          description = ''
            Type of the route. See the `Route types` section in the
            {manpage}`ip-route(8)` manual page for the details.
          '';
        };
        via = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            The next hop of this route.
          '';
        };
        extraOptions = mkOption {
          type = types.submodule {
            freeformType = (pkgs.formats.json { }).type;
          };
          default = { };
          description = ''
            Extra route options. See the symbol `OPTIONS` in the
            {manpage}`ip-route(8)` manual page for the details.
          '';
        };
      };
    };

  interfaceOptions =
    { ... }:
    {
      options = {
        addresses = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = ''
            List of addresses in CIDR representation that will be
            statically assigned to the interface.
          '';
        };
        routes = mkOption {
          type = types.listOf (types.submodule routeOptions);
          default = [ ];
          description = ''
            List of extra static routes that will be assigned to
            the interface.
          '';
        };
        netdevDependencies = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = ''
            A list of additional systemd services that must be active
            before the network interface configuration takes place.
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
            interfaces = mkOption {
              type = types.attrsOf (types.submodule interfaceOptions);
              default = { };
              description = ''
                Per-network namespace network interfaces configuration.
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
            nameValuePair "netns-${name}-interface-${n}" (
              mkIf cfg.enable {
                path = with pkgs; [ iproute2 ];
                script = ''
                  state="${cfg.runtimeDirectory}/network/addresses/${n}"
                  mkdir -p "$(dirname "$state")"

                  ip link set dev "${n}" up

                  ${concatMapStrings (addr: ''
                    echo "${addr}" >> $state
                    echo -n "adding address ${addr}... "
                    if out=$(ip addr replace "${addr}" dev "${n}" 2>&1); then
                      echo "done"
                    else
                      echo "'ip addr replace \"${addr}\" dev \"${n}\"' failed: $out"
                      exit 1
                    fi
                  '') v.addresses}

                  state="${cfg.runtimeDirectory}/network/routes/${n}"
                  mkdir -p "$(dirname "$state")"

                  ${concatMapStrings (
                    route:
                    let
                      inherit (route) cidr;
                      type = toString route.type;
                      via = optionalString (route.via != null) "via \"${route.via}\"";
                      options = attrsToString route.extraOptions;
                    in
                    ''
                      echo "${cidr}" >> $state
                      echo -n "adding route ${cidr}... "
                       if out=$(ip route replace ${type} "${cidr}" ${options} ${via} dev "${n}" proto static 2>&1); then
                         echo "done"
                       else
                         echo "'ip route replace ${type} \"${cidr}\" ${options} ${via} dev \"${n}\"' failed: $out"
                         exit 1
                       fi
                    ''
                  ) v.routes}
                '';
                preStop = ''
                  state="${cfg.runtimeDirectory}/network/routes/${n}"
                  if [ -e "$state" ]; then
                    while read -r cidr; do
                      echo -n "deleting route $cidr... "
                      ip route del "$cidr" dev "${n}" >/dev/null 2>&1 && echo "done" || echo "failed"
                    done < "$state"
                    rm -f "$state"
                  fi

                  state="${cfg.runtimeDirectory}/network/addresses/${n}"
                  if [ -e "$state" ]; then
                    while read -r cidr; do
                      echo -n "deleting address $cidr... "
                      ip addr del "$cidr" dev "${n}" >/dev/null 2>&1 && echo "done" || echo "failed"
                    done < "$state"
                    rm -f "$state"
                  fi
                '';
                serviceConfig = {
                  Type = "oneshot";
                  RemainAfterExit = true;
                  NetworkNamespacePath = cfg.netnsPath;
                };
                after = [
                  "netns-${name}.service"
                ] ++ v.netdevDependencies;
                partOf = [
                  "netns-${name}.service"
                ] ++ v.netdevDependencies;
                wantedBy = [
                  "netns-${name}.service"
                  "multi-user.target"
                ] ++ v.netdevDependencies;
              }
            )
          ) cfg.interfaces
        ) config.networking.netns-ng
      )
    );
  };
}
