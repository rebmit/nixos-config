{ lib, pkgs, ... }:
let
  importBase24Theme =
    file:
    let
      inherit (builtins.fromTOML (builtins.readFile file)) palette;
    in
    builtins.mapAttrs (_name: value: builtins.substring 1 6 value) palette;
in
{
  theme = {
    cursorTheme = "capitaine-cursors-white";
    cursorSize = 36;

    light = {
      iconTheme = "Papirus-Light";
      gtkTheme = "adw-gtk3";
      wallpaper = "${pkgs.nixos-artwork.wallpapers.nineish}/share/backgrounds/nixos/nix-wallpaper-nineish.png";
      kittyTheme = "${./_kitty/adwaita_light.conf}";
      helixTheme = "${pkgs.helix}/lib/runtime/themes/adwaita-light.toml";
      base24Theme = importBase24Theme ./adwaita-light.toml;
    };

    dark = {
      iconTheme = "Papirus-Dark";
      gtkTheme = "adw-gtk3-dark";
      wallpaper = "${pkgs.nixos-artwork.wallpapers.nineish-dark-gray}/share/backgrounds/nixos/nix-wallpaper-nineish-dark-gray.png";
      kittyTheme = "${./_kitty/adwaita_dark.conf}";
      helixTheme = "${pkgs.helix}/lib/runtime/themes/adwaita-dark.toml";
      base24Theme = importBase24Theme ./adwaita-dark.toml;
    };
  };

  home.packages = lib.mkIf pkgs.stdenv.hostPlatform.isLinux (
    with pkgs;
    [
      papirus-icon-theme
      capitaine-cursors
      adw-gtk3
    ]
  );
}
