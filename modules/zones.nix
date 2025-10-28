{
  inputs,
  lib,
  flake-parts-lib,
  ...
}:
let
  inherit (lib.types) attrsOf submodule;
  inherit (lib.attrsets) mapAttrs;
  inherit (lib.options) mkOption;
  inherit (inputs.rebmit.lib.types) mkStructuredType;
  inherit (flake-parts-lib) mkSubmoduleOptions;
in
{
  options.flake = mkSubmoduleOptions {
    zones = mkOption {
      type = attrsOf (submodule {
        freeformType = mkStructuredType { typeName = "zone"; };
      });
      default = { };
      apply = mapAttrs inputs.dns.lib.toString;
      description = ''
        A set of DNS zones managed by this flake.
      '';
    };
  };
}
