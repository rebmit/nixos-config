# Portions of this file are sourced from
# https://github.com/linyinfeng/dotfiles/blob/b618b0fd16fb9c79ab7199ed51c4c0f98a392cea/flake/hosts.nix (MIT License)
{
  config,
  inputs,
  self,
  lib,
  getSystem,
  ...
}:
let
  inherit (config.passthru)
    nixosModules
    nixosProfiles
    nixosSuites
    homeModules
    homeProfiles
    homeSuites
    ;

  data = builtins.fromJSON (builtins.readFile ../zones/data.json);
  mylib = inputs.rebmit.lib;

  nixosSpecialArgs = name: {
    inherit
      inputs
      self
      data
      mylib
      ;
    profiles = nixosProfiles;
    suites = nixosSuites;
    hostData = data.hosts."${name}";
  };

  homeSpecialArgs = name: {
    inherit
      inputs
      self
      data
      mylib
      ;
    profiles = homeProfiles;
    suites = homeSuites;
    hostData = data.hosts."${name}";
  };

  darwinSpecialArgs = name: {
    inherit
      inputs
      self
      data
      mylib
      ;
    hostData = data.hosts."${name}";
  };

  commonNixosModules =
    name:
    nixosModules
    ++ [
      inputs.home-manager.nixosModules.home-manager
      inputs.sops-nix.nixosModules.sops
      inputs.disko.nixosModules.disko

      (
        { ... }:
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            sharedModules = commonHomeModules name;
            extraSpecialArgs = homeSpecialArgs name;
          };
        }
      )
    ];

  commonHomeModules =
    _name:
    homeModules
    ++ [
      inputs.niri-flake.homeModules.niri

      (
        { osConfig, ... }:
        {
          home.stateVersion = osConfig.system.stateVersion;
        }
      )
    ];

  commonDarwinModules = name: [
    inputs.home-manager.darwinModules.home-manager
    (
      { ... }:
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          sharedModules = commonDarwinHomeModules name;
          extraSpecialArgs = homeSpecialArgs name;
        };
      }
    )
  ];

  commonDarwinHomeModules =
    _name:
    homeModules
    ++ [
      inputs.niri-flake.homeModules.niri

      {
        home.stateVersion = lib.mkDefault "24.11";
      }
    ];

  mkHost =
    {
      name,
      configurationName ? name,
      nixpkgs ? inputs.nixpkgs,
      system,
      forceFlakeNixpkgs ? true,
    }:
    {
      ${name} = nixpkgs.lib.nixosSystem {
        specialArgs = nixosSpecialArgs name;
        modules =
          (commonNixosModules name)
          ++ lib.optional (configurationName != null) ../nixos/hosts/${configurationName}
          ++ [
            (
              { lib, ... }:
              {
                networking.hostName = lib.mkDefault name;
              }
            )
            (
              if forceFlakeNixpkgs then
                {
                  imports = [ nixpkgs.nixosModules.readOnlyPkgs ];
                  nixpkgs = {
                    inherit ((getSystem system).allModuleArgs) pkgs;
                  };
                }
              else
                {
                  nixpkgs = {
                    inherit ((getSystem system).nixpkgs) config overlays;
                  };
                }
            )
          ];
      };
    };

  mkDarwinHost =
    {
      name,
      configurationName ? name,
      nixpkgs ? inputs.nixpkgs,
      nix-darwin ? inputs.nix-darwin,
      system,
    }:
    {
      ${name} = nix-darwin.lib.darwinSystem {
        specialArgs = darwinSpecialArgs name;
        modules =
          (commonDarwinModules name)
          ++ lib.optional (configurationName != null) ../darwin/hosts/${configurationName}
          ++ [
            (
              { lib, ... }:
              {
                networking.hostName = lib.mkDefault name;
                networking.computerName = lib.mkDefault name;
              }
            )
            {
              nixpkgs = {
                inherit ((getSystem system).nixpkgs) config overlays;
                hostPlatform = system;
              };
            }
          ];
      };
    };
in
{
  flake.nixosConfigurations = lib.mkMerge [
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

  flake.darwinConfigurations = lib.mkMerge [
    (mkDarwinHost {
      name = "marisa-j715";
      system = "aarch64-darwin";
    })
  ];
}
