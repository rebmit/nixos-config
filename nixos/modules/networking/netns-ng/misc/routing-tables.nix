{
  config,
  lib,
  ...
}:
let
  inherit (lib) types;
  inherit (lib.options) mkOption;
  inherit (lib.attrsets) mapAttrsToList attrValues filterAttrs;
  inherit (lib.strings) concatStringsSep;
  inherit (lib.lists) flatten length unique;

  noCollision = l: length (unique l) == length l;
  reservedTables = [
    "local"
    "main"
    "default"
    "unspec"
  ];
in
{
  options.networking.netns-ng = mkOption {
    type = types.attrsOf (
      types.submodule (
        { config, ... }:
        {
          options.misc = {
            routingTables = mkOption {
              type = with types; attrsOf int;
              default = { };
              description = ''
                A mapping of routing tables, each identified by a unique name.
              '';
            };
            routingMarks = mkOption {
              type = with types; attrsOf int;
              default = { };
              description = ''
                A mapping of routing marks, each identified by a unique name.
              '';
            };
            routingPolicyPriorities = mkOption {
              type = with types; attrsOf int;
              default = { };
              description = ''
                A set of priorities for routing policies.
              '';
            };
          };

          config = {
            misc.routingTables = {
              unspec = 0;
              default = 253;
              main = 254;
              local = 255;
            };

            misc.routingPolicyPriorities = {
              local = 0;
              main = 32766;
              default = 32767;
            };

            confext."iproute2/rt_tables.d/routing_tables.conf".text = ''
              ${concatStringsSep "\n" (
                mapAttrsToList (name: table: "${toString table} ${name}") (
                  filterAttrs (name: _table: !(builtins.elem name reservedTables)) config.misc.routingTables
                )
              )}
            '';
          };
        }
      )
    );
  };

  config = {
    assertions = flatten (
      mapAttrsToList (name: cfg: [
        {
          assertion = noCollision (attrValues cfg.misc.routingTables);
          message = "routing table id collision in named netns ${name}";
        }
        {
          assertion = noCollision (attrValues cfg.misc.routingMarks);
          message = "routing mark id collision in named netns ${name}";
        }
        {
          assertion = noCollision (attrValues cfg.misc.routingPolicyPriorities);
          message = "routing policy priority collision in named netns ${name}";
        }
      ]) config.networking.netns-ng
    );

    networking.netns-ng = {
      enthalpy-ng = {
        misc.routingTables = {
          plat = 400;
          localsid = 500;
        };
        misc.routingPolicyPriorities = {
          localsid = 500;
        };
      };
    };
  };
}
