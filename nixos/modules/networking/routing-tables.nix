{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.networking;
  noCollision = l: length (unique l) == length l;
  reservedTables = [
    "local"
    "main"
    "default"
    "unspec"
  ];
in
{
  options.networking = {
    routingTables = mkOption {
      type = with types; attrsOf int;
      default = {
        # reserved
        unspec = 0;
        default = 253;
        main = 254;
        local = 255;

        # enthalpy
        localsid = 300;
        nat64 = 301;

        plat = 400;
      };
      readOnly = true;
      description = ''
        A mapping of routing tables, each identified by a unique name.
      '';
    };
    routingMarks = mkOption {
      type = with types; attrsOf int;
      default = { };
      readOnly = true;
      description = ''
        A mapping of routing marks, each identified by a unique name.
      '';
    };
    routingPolicyPriorities = mkOption {
      type = with types; attrsOf int;
      default = {
        # reserved
        local = 0;
        main = 32766;
        default = 32767;

        plat = 400;

        # enthalpy
        localsid = 500;
      };
      readOnly = true;
      description = ''
        A set of priorities for routing policies.
      '';
    };
  };

  config = {
    assertions = [
      {
        assertion = noCollision (attrValues cfg.routingTables);
        message = "routing table id collision";
      }
      {
        assertion = noCollision (attrValues cfg.routingMarks);
        message = "routing mark id collision";
      }
      {
        assertion = noCollision (attrValues cfg.routingPolicyPriorities);
        message = "routing policy priority collision";
      }
    ];

    environment.etc."iproute2/rt_tables.d/routing_tables.conf" = {
      mode = "0644";
      text = ''
        ${concatStringsSep "\n" (
          mapAttrsToList (name: table: "${toString table} ${name}") (
            filterAttrs (name: _table: !(lib.elem name reservedTables)) cfg.routingTables
          )
        )}
      '';
    };
  };
}
