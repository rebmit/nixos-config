{
  config,
  lib,
  ...
}:
let
  inherit (lib) types;
  inherit (lib.options) mkOption;
  inherit (lib.attrsets) mapAttrsToList attrValues;
  inherit (lib.lists) flatten length unique;

  noCollision = l: length (unique l) == length l;
in
{
  options.networking.netns = mkOption {
    type = types.attrsOf (
      types.submodule (
        { ... }:
        {
          options = {
            ports = mkOption {
              type = with types; attrsOf port;
              default = { };
              description = ''
                A mapping of network ports, each identified by a unique name.
              '';
            };
          };
        }
      )
    );
  };

  config = {
    assertions = flatten (
      mapAttrsToList (name: cfg: [
        {
          assertion = noCollision (attrValues cfg.ports);
          message = "port collision in named netns ${name}";
        }
      ]) config.networking.netns
    );
  };
}
