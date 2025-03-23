{
  inputs,
  lib,
  self,
  ...
}:
let
  inherit (lib.attrsets) filterAttrs mapAttrs;

  flakes = filterAttrs (_name: value: value ? _type && value._type == "flake") inputs;
  nixRegistry = mapAttrs (_name: value: { flake = value; }) flakes;
in
{
  nix = {
    registry = nixRegistry // {
      p.flake = self;
    };
    settings.flake-registry = "/etc/nix/registry.json";
  };
}
