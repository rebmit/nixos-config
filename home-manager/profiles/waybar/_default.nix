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
      inherit (config.theme.${mode}) base24Theme;
    in
    pkgs.writeText "waybar-style-${mode}.css" (import ./_style.nix base24Theme);
in
{
  programs.waybar = {
    enable = true;
    systemd.enable = true;
  };

  systemd.user.services.waybar = {
    Unit = {
      ConditionEnvironment = lib.singleton "WAYLAND_DISPLAY";
      Requisite = lib.singleton "graphical-session.target";
      After = lib.singleton "graphical-session.target";
    };
  };

  systemd.user.tmpfiles.rules = [
    "L %h/.config/waybar/style.css - - - - ${mkTheme "light"}"
  ];

  services.darkman =
    let
      mkScript =
        mode:
        pkgs.writeShellApplication {
          name = "darkman-switch-waybar-${mode}";
          text = ''
            ln --force --symbolic --verbose "${mkTheme mode}" "$HOME/.config/waybar/style.css"
            pkill -u "$USER" -USR2 waybar || true
          '';
        };
    in
    {
      lightModeScripts.waybar = "${lib.getExe (mkScript "light")}";
      darkModeScripts.waybar = "${lib.getExe (mkScript "dark")}";
    };
}
