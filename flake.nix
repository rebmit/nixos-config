{
  description = "a nixos configuration collection by rebmit";

  outputs =
    inputs@{ flake-parts, rebmit, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      inherit (rebmit.lib) systems;
      imports = [
        inputs.devshell.flakeModule
        inputs.git-hooks-nix.flakeModule
        inputs.treefmt-nix.flakeModule
        inputs.rebmit.flakeModule
      ] ++ rebmit.lib.path.buildModuleList ./flake;
    };

  inputs = {
    # flake-parts

    flake-parts.follows = "rebmit/flake-parts";

    # nixpkgs

    nixpkgs.follows = "rebmit/nixpkgs";
    nixpkgs-unstable.follows = "rebmit/nixpkgs-unstable";

    # flake modules

    devshell.follows = "rebmit/devshell";
    git-hooks-nix.follows = "rebmit/git-hooks-nix";
    treefmt-nix.follows = "rebmit/treefmt-nix";

    # nixos modules

    preservation.url = "github:nix-community/preservation";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko/v1.11.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # darwin modules

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
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
    nixpkgs-firefox-darwin = {
      url = "github:bandithedoge/nixpkgs-firefox-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # libraries

    rebmit.url = "https://git.rebmit.moe/rebmit/nix-exprs/archive/master.tar.gz";
    enthalpy = {
      url = "https://git.rebmit.moe/rebmit/enthalpy/archive/master.tar.gz";
      inputs.rebmit.follows = "rebmit";
    };
    flake-utils.url = "github:numtide/flake-utils";
    dns = {
      url = "github:NickCao/dns.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };
}
