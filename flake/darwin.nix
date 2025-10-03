# Portions of this file are sourced from
# https://github.com/linyinfeng/dotfiles/blob/b618b0fd16fb9c79ab7199ed51c4c0f98a392cea/flake/hosts.nix (MIT License)
{
  config,
  inputs,
  data,
  mylib,
  self,
  lib,
  getSystem,
  ...
}:
let
  inherit (lib.modules) mkDefault mkMerge;
  inherit (lib.lists) singleton optional;
  inherit (config.passthru) homeSpecialArgs homeCommonModules;

  darwinSpecialArgs = name: {
    inherit
      inputs
      self
      data
      mylib
      ;
    host = data.hosts."${name}";
  };

  darwinCommonModules = name: [
    inputs.home-manager.darwinModules.home-manager

    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        sharedModules =
          homeCommonModules name
          ++ singleton (_: {
            home.stateVersion = "24.11";
          });
        extraSpecialArgs = homeSpecialArgs name;
      };
    }
  ];

  mkHost =
    {
      name,
      configurationName ? name,
      nix-darwin ? inputs.nix-darwin,
      system,
    }:
    {
      ${name} = nix-darwin.lib.darwinSystem {
        specialArgs = darwinSpecialArgs name;
        modules =
          (darwinCommonModules name)
          ++ optional (configurationName != null) ../darwin/hosts/${configurationName}
          ++ [
            {
              nixpkgs = {
                inherit ((getSystem system).nixpkgs) config overlays;
                hostPlatform = system;
              };
              networking.hostName = mkDefault name;
              networking.computerName = mkDefault name;
            }
          ];
      };
    };
in
{
  passthru = {
    inherit
      darwinSpecialArgs
      darwinCommonModules
      ;
  };

  flake.darwinConfigurations = mkMerge [
    (mkHost {
      name = "marisa-j715";
      system = "aarch64-darwin";
    })
  ];
}
