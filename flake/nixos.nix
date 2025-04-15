# Portions of this file are sourced from
# https://github.com/linyinfeng/dotfiles/blob/b618b0fd16fb9c79ab7199ed51c4c0f98a392cea/flake/hosts.nix (MIT License)
{
  inputs,
  self,
  data,
  config,
  lib,
  mylib,
  getSystem,
  ...
}:
let
  inherit (lib.modules) mkDefault mkMerge;
  inherit (lib.lists) singleton optional fold;
  inherit (lib.attrsets) recursiveUpdate mapAttrsToList;
  inherit (mylib.path) buildModuleList rakeLeaves;
  inherit (config.passthru) homeSpecialArgs homeCommonModules;

  nixosModules = buildModuleList ../nixos/modules;
  nixosProfiles = rakeLeaves ../nixos/profiles;
  nixosSuites = rakeLeaves ../nixos/suites;

  nixosSpecialArgs = name: {
    inherit
      inputs
      self
      data
      mylib
      ;
    profiles = nixosProfiles;
    suites = nixosSuites;
    host = data.hosts."${name}";
  };

  nixosCommonModules =
    name:
    nixosModules
    ++ [
      inputs.home-manager.nixosModules.home-manager
      inputs.sops-nix.nixosModules.sops
      inputs.disko.nixosModules.disko

      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          sharedModules =
            homeCommonModules name
            ++ singleton (
              { osConfig, ... }:
              {
                home.stateVersion = osConfig.system.stateVersion;
              }
            );
          extraSpecialArgs = homeSpecialArgs name;
        };
      }
    ];

  mkHost =
    {
      name,
      configurationName ? name,
      nixpkgs ? inputs.nixpkgs,
      system,
    }:
    {
      ${name} = nixpkgs.lib.nixosSystem {
        specialArgs = nixosSpecialArgs name;
        modules =
          (nixosCommonModules name)
          ++ optional (configurationName != null) ../nixos/hosts/${configurationName}
          ++ [
            (
              { ... }:
              {
                imports = [ nixpkgs.nixosModules.readOnlyPkgs ];
                nixpkgs = {
                  inherit ((getSystem system).allModuleArgs) pkgs;
                };
                networking.hostName = mkDefault name;
              }
            )
          ];
      };
    };

  getHostToplevel =
    name: cfg:
    let
      inherit (cfg.pkgs.stdenv.hostPlatform) system;
    in
    {
      "${system}"."nixos-system-${name}" = cfg.config.system.build.toplevel;
    };
in
{
  passthru = {
    inherit
      nixosModules
      nixosProfiles
      nixosSuites
      nixosSpecialArgs
      nixosCommonModules
      ;
  };

  flake.nixosConfigurations = mkMerge [
    (mkHost {
      name = "marisa-7d76";
      system = "x86_64-linux";
    })

    (mkHost {
      name = "marisa-j715";
      system = "aarch64-linux";
    })

    (mkHost {
      name = "flandre-m5p";
      system = "x86_64-linux";
    })

    (mkHost {
      name = "kanako-ham0";
      system = "x86_64-linux";
    })

    (mkHost {
      name = "suwako-vie0";
      system = "x86_64-linux";
    })

    (mkHost {
      name = "suwako-vie1";
      system = "x86_64-linux";
    })

    (mkHost {
      name = "reisen-sea0";
      system = "x86_64-linux";
    })

    (mkHost {
      name = "reisen-nrt0";
      system = "x86_64-linux";
    })

    (mkHost {
      name = "reisen-sin0";
      system = "x86_64-linux";
    })

    (mkHost {
      name = "reisen-ams0";
      system = "x86_64-linux";
    })
  ];

  flake.checks = fold recursiveUpdate { } (mapAttrsToList getHostToplevel self.nixosConfigurations);
}
