{
  description = "a nixos configuration collection by rebmit";

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { lib, ... }:
      let
        inherit (lib.strings) fromJSON;
        inherit (lib.trivial) readFile;

        data = fromJSON (readFile ./zones/data.json);
        mylib = inputs.rebmit.lib;
      in
      {
        _module.args = { inherit data mylib; };
        inherit (mylib) systems;
        imports = [
          inputs.devshell.flakeModule
          inputs.git-hooks-nix.flakeModule
          inputs.treefmt-nix.flakeModule
          inputs.rebmit.flakeModule
        ]
        ++ mylib.path.buildModuleList ./flake;
      }
    );

  inputs = {
    # flake-parts

    flake-parts.follows = "rebmit/flake-parts";

    # nixpkgs

    nixpkgs.url = "github:rebmit/nixpkgs/nixos-unstable";

    # flake modules

    devshell.follows = "rebmit/devshell";
    git-hooks-nix.follows = "rebmit/git-hooks-nix";
    treefmt-nix.follows = "rebmit/treefmt-nix";

    # nixos modules

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # darwin modules

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # programs

    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };
    nixpkgs-terraform-providers-bin = {
      url = "github:nix-community/nixpkgs-terraform-providers-bin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # libraries

    rebmit = {
      url = "github:rebmit/nix-exprs/c688055a14c3edeae77c3814b20d5430b51c533f";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rebmit-next = {
      url = "github:rebmit/nix-exprs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    dns = {
      url = "github:nix-community/dns.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };
}
