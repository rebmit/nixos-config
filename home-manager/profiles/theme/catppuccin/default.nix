{ pkgs, ... }:
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
      gtkTheme = "catppuccin-latte-blue-compact";
      wallpaper = "${pkgs.nixos-artwork.wallpapers.nineish}/share/backgrounds/nixos/nix-wallpaper-nineish.png";
      kittyTheme = "${pkgs.kitty-themes}/share/kitty-themes/themes/Catppuccin-Latte.conf";
      helixTheme = "${pkgs.helix}/lib/runtime/themes/catppuccin_latte.toml";
      base24Theme = importBase24Theme ./catppuccin-latte.toml;
    };

    dark = {
      iconTheme = "Papirus-Dark";
      gtkTheme = "catppuccin-frappe-blue-compact";
      wallpaper = "${pkgs.nixos-artwork.wallpapers.nineish-dark-gray}/share/backgrounds/nixos/nix-wallpaper-nineish-dark-gray.png";
      kittyTheme = "${pkgs.kitty-themes}/share/kitty-themes/themes/Catppuccin-Frappe.conf";
      helixTheme = "${pkgs.helix}/lib/runtime/themes/catppuccin_frappe.toml";
      base24Theme = importBase24Theme ./catppuccin-frappe.toml;
    };
  };

  home.packages = with pkgs; [
    papirus-icon-theme
    capitaine-cursors
    (catppuccin-gtk.override {
      accents = [ "blue" ];
      size = "compact";
      variant = "latte";
    })
    (catppuccin-gtk.override {
      accents = [ "blue" ];
      size = "compact";
      variant = "frappe";
    })
  ];
}
