{ config, lib, ... }:
let
  inherit (lib.modules) mkMerge;
  inherit (lib.attrsets)
    mapAttrsToList
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

    preservation = {
      enable = true;
      persistentStoragePath = "/persist";
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
    preservation = mkMerge (
      mapAttrsToList (name: hmCfg: {
        users.${name} = {
          home = hmCfg.home.homeDirectory;
          inherit (hmCfg.preservation) directories files;
        };
      }) (filterAttrs (_: hmCfg: hmCfg.preservation.enable) config.home-manager.users)
    );
  }
]
