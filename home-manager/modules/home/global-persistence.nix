# Portions of this file are sourced from
# https://github.com/linyinfeng/dotfiles/blob/b618b0fd16fb9c79ab7199ed51c4c0f98a392cea/home-manager/modules/home/global-persistence.nix
{
  config,
  lib,
  osConfig,
  ...
}:
with lib;
let
  cfg = config.home.globalPersistence;
  sysCfg = osConfig.environment.globalPersistence;
in
{
  options.home.globalPersistence = {
    enable = mkEnableOption "global presistence storage";
    home = mkOption {
      type = types.str;
      description = ''
        Home directory.
      '';
    };
    directories = mkOption {
      type = with types; listOf str;
      default = [ ];
      description = ''
        A list of directories in your home directory that you want to link to persistent storage.
      '';
    };
    files = mkOption {
      type = with types; listOf str;
      default = [ ];
      description = ''
        A list of files in your home directory you want to link to persistent storage.
      '';
    };
    enabled = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Is global home persistence storage enabled.
      '';
    };
  };

  config = mkIf (osConfig != null && sysCfg.enable) {
    home.globalPersistence = {
      inherit (sysCfg.user) directories;
      inherit (sysCfg.user) files;
      enabled = cfg.enable;
    };
  };
}
