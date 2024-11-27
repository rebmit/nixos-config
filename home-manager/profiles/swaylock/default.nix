# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/3b03efb676ea602575c916b2b8bc9d9cd13b0d85/nixos/mainframe/home.nix
{
  config,
  pkgs,
  lib,
  ...
}:
let
  mkBlurredWallpaper =
    mode:
    pkgs.runCommand "wallpaper-blurred-${mode}" { nativeBuildInputs = with pkgs; [ imagemagick ]; } ''
      magick convert -blur 14x5 ${config.theme.${mode}.wallpaper} $out
    '';
in
{
  programs.swaylock = {
    enable = true;
    settings = {
      show-failed-attempts = true;
      daemonize = true;
      image = "~/.config/swaylock/image";
      scaling = "fill";
    };
  };

  systemd.user.tmpfiles.rules = [
    "L %h/.config/swaylock/image - - - - ${mkBlurredWallpaper "light"}"
  ];

  services.darkman =
    let
      mkScript =
        mode:
        pkgs.writeShellApplication {
          name = "darkman-switch-swaylock-${mode}";
          text = ''
            ln --force --symbolic --verbose "${mkBlurredWallpaper mode}" "$HOME/.config/swaylock/image"
          '';
        };
    in
    {
      lightModeScripts.swaylock = "${lib.getExe (mkScript "light")}";
      darkModeScripts.swaylock = "${lib.getExe (mkScript "dark")}";
    };
}
