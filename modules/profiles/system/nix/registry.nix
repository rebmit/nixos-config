{ self, ... }:
let
  common = _: {
    nixpkgs.flake = {
      setFlakeRegistry = true;
      setNixPath = true;
    };

    nix = {
      registry.p.flake = self;
      settings = {
        flake-registry = "/etc/nix/registry.json";
      };
    };
  };
in
{
  flake.modules.nixos."system/nix/registry".imports = [
    common
  ];

  flake.modules.darwin."system/nix/registry".imports = [
    common
  ];
}
