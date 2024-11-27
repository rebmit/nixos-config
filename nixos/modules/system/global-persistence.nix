# Portions of this file are sourced from
# https://github.com/linyinfeng/dotfiles/blob/b618b0fd16fb9c79ab7199ed51c4c0f98a392cea/nixos/modules/environment/global-persistence/default.nix
{
  config,
  lib,
  ...
}:
let
  cfg = config.environment.globalPersistence;
  userCfg =
    name:
    assert config.home-manager.users.${name}.home.globalPersistence.enabled;
    {
      inherit name;
      value = {
        inherit (config.home-manager.users.${name}.home.globalPersistence) home directories files;
      };
    };
  usersCfg = lib.listToAttrs (map userCfg cfg.user.users);
in
with lib;
{
  options.environment.globalPersistence = {
    enable = mkEnableOption "global persistence storage";
    root = mkOption {
      type = types.str;
      description = ''
        The root of persistence storage.
      '';
    };
    directories = mkOption {
      type = with types; listOf str;
      default = [ ];
      description = ''
        Directories to bind mount to persistent storage.
      '';
    };
    files = mkOption {
      type = with types; listOf str;
      default = [ ];
      description = ''
        Files that should be stored in persistent storage.
      '';
    };
    user = {
      users = mkOption {
        type = with types; listOf str;
        default = [ ];
        description = ''
          Persistence for users.
        '';
      };
      directories = mkOption {
        type = with types; listOf str;
        default = [ ];
        description = ''
          Directories to bind mount to persistent storage for users.
          Paths should be relative to home of user.
        '';
      };
      files = mkOption {
        type = with types; listOf str;
        default = [ ];
        description = ''
          Files to link to persistent storage for users.
          Paths should be relative to home of user.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    environment.persistence."${cfg.root}" = {
      hideMounts = true;
      inherit (cfg) directories files;
      users = usersCfg;
    };
  };
}
