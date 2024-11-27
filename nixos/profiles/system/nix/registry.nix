{
  inputs,
  lib,
  self,
  ...
}:
let
  flakes = lib.filterAttrs (_name: value: value ? _type && value._type == "flake") inputs;
  nixRegistry = (lib.mapAttrs (_name: value: { flake = value; }) flakes);
in
{
  nix = {
    registry = nixRegistry // {
      p.flake = self;
    };
    settings.flake-registry = "/etc/nix/registry.json";
  };
}
