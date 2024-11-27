{
  config,
  pkgs,
  lib,
  ...
}:
let
  mkTheme =
    mode:
    let
      inherit (config.theme.${mode}.base24Theme)
        base00
        base04
        base05
        base08
        base0D
        ;
    in
    (pkgs.formats.ini { }).generate "fuzzel-theme-${mode}.ini" {
      colors = {
        background = "${base00}dd";
        text = "${base05}ff";
        match = "${base08}ff";
        selection = "${base04}ff";
        selection-text = "${base05}ff";
        selection-match = "${base08}ff";
        border = "${base0D}ff";
      };
    };
in
{
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        fields = "filename,name,generic,exec,keywords";
        font = "monospace:size=11";
        dpi-aware = "no";
        layer = "overlay";
      };
      border = {
        width = "2";
        radius = "0";
      };
    };
  };

  programs.fuzzel.settings.main.include = "~/.config/fuzzel/theme.ini";

  systemd.user.tmpfiles.rules = [
    "L %h/.config/fuzzel/theme.ini - - - - ${mkTheme "light"}"
  ];

  services.darkman =
    let
      mkScript =
        mode:
        pkgs.writeShellApplication {
          name = "darkman-switch-fuzzel-${mode}";
          text = ''
            ln --force --symbolic --verbose "${mkTheme mode}" "$HOME/.config/fuzzel/theme.ini"
          '';
        };
    in
    {
      lightModeScripts.fuzzel = "${lib.getExe (mkScript "light")}";
      darkModeScripts.fuzzel = "${lib.getExe (mkScript "dark")}";
    };
}
