{ lib, ... }:
with lib;
let
  themeOpts.options = {
    iconTheme = mkOption {
      type = types.str;
      description = ''
        The icon theme to use.
      '';
    };
    gtkTheme = mkOption {
      type = types.str;
      description = ''
        The GTK theme to use.
      '';
    };
    wallpaper = mkOption {
      type = types.str;
      description = ''
        The path to the wallpaper to use.
      '';
    };
    kittyTheme = mkOption {
      type = types.str;
      description = ''
        The path to the kitty theme to use.
      '';
    };
    helixTheme = mkOption {
      type = types.str;
      description = ''
        The path to the helix theme to use.
      '';
    };
    base24Theme = mkOption { };
  };
in
{
  options.theme = {
    cursorTheme = mkOption {
      type = types.str;
      description = ''
        The cursor theme to use.
      '';
    };
    cursorSize = mkOption {
      type = types.int;
      description = ''
        The size of the cursor.
      '';
    };

    light = mkOption {
      type = types.submodule themeOpts;
      default = { };
      description = ''
        The light theme configuration.
      '';
    };
    dark = mkOption {
      type = types.submodule themeOpts;
      default = { };
      description = ''
        The dark theme configuration.
      '';
    };
  };
}
