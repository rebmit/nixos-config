{
  config,
  lib,
  ...
}:
with lib;
let
  noCollision = l: length (unique l) == length l;
  reservedTables = [
    "local"
    "main"
    "default"
    "unspec"
  ];
in
{
  options = {
    routingTables = mkOption {
      type = with types; attrsOf int;
      default = {
        # reserved
        unspec = 0;
        default = 253;
        main = 254;
        local = 255;

        # enthalpy
        plat = 400;
        enthalpy = 410;
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
        enthalpy = 1000;
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
        assertion = noCollision (attrValues config.routingTables);
        message = "routing table id collision";
      }
      {
        assertion = noCollision (attrValues config.routingMarks);
        message = "routing mark id collision";
      }
      {
        assertion = noCollision (attrValues config.routingPolicyPriorities);
        message = "routing policy priority collision";
      }
    ];

    environment.etc."iproute2/rt_tables.d/routing_tables.conf" = {
      mode = "0644";
      text = ''
        ${concatStringsSep "\n" (
          mapAttrsToList (name: table: "${toString table} ${name}") (
            filterAttrs (name: _table: !(lib.elem name reservedTables)) config.routingTables
          )
        )}
      '';
    };
  };
}
