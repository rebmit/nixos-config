{ inputs, self, ... }:
{
  nix = {
    registry.p.flake = self;
    settings = {
      flake-registry = "/etc/nix/registry.json";
      nix-path = [ "nixpkgs=${inputs.nixpkgs}" ];
    };
  };

  nixpkgs.flake = {
    setNixPath = false;
    setFlakeRegistry = true;
  };
}
