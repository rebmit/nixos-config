{ config, lib, ... }:
let
  inherit (lib.modules) mkMerge;
  inherit (lib.attrsets)
    mapAttrsToList
    mapAttrs
    filterAttrs
    ;
in
mkMerge [
  {
    assertions = [
      {
        assertion = config.fileSystems ? "/persist";
        message = ''
          `config.fileSystems."/persist"` must be set.
        '';
      }
    ];

    preservation.enable = true;

    preservation.preserveAt."/persist" = {
      directories = [
        {
          directory = "/var/lib/nixos";
          inInitrd = true;
          mode = "0755";
          user = "root";
          group = "root";
        }
      ];
    };
  }
  {
    preservation.preserveAt = mkMerge (
      mapAttrsToList (
        name: hmCfg:
        mapAttrs (_: preserve: {
          users.${name} = {
            home = hmCfg.home.homeDirectory;
            inherit (preserve) directories files;
          };
        }) hmCfg.preservation.preserveAt
      ) (filterAttrs (_: hmCfg: hmCfg.preservation.enable) config.home-manager.users)
    );
  }
]
