{
  config,
  lib,
  osConfig,
  ...
}:
with lib;
let
  cfg = config.preservation;
  sysCfg = osConfig.preservation;
in
{
  options.preservation = {
    enable = mkEnableOption "the preservation module";
    directories = mkOption {
      type = with types; listOf (coercedTo str (d: { directory = d; }) anything);
      default = [ ];
      description = ''
        Specify a list of directories that should be preserved for this user.
        The paths are interpreted relative to the user's home directory.
      '';
    };
    files = mkOption {
      type = with types; listOf (coercedTo str (f: { file = f; }) anything);
      default = [ ];
      description = ''
        Specify a list of files that should be preserved for this user.
        The paths are interpreted relative to the user's home directory.
      '';
    };
  };

  config = {
    warnings = mkIf (cfg.enable && !sysCfg.enable) [
      ''
        The preservation module is enabled in Home Manager but disabled system-wide.
        As a result, the settings will not take effect.
      ''
    ];
  };
}
