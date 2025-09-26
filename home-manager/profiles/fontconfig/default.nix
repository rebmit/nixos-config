{ lib, pkgs, ... }:
let
  inherit (lib.strings) concatMapStringsSep;
in
{
  fonts.fontconfig.enable = lib.mkForce false;

  xdg.configFile."fontconfig/conf.d/10-hm-fonts.conf".text =
    let
      fonts = with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-emoji
        roboto-mono
        nerd-fonts.roboto-mono
      ];
      cache = pkgs.makeFontsCache {
        inherit (pkgs) fontconfig;
        fontDirectories = fonts;
      };
    in
    ''
      <?xml version='1.0'?>
      <!DOCTYPE fontconfig SYSTEM 'urn:fontconfig:fonts.dtd'>
      <fontconfig>
        ${concatMapStringsSep "\n" (font: "<dir>${font}</dir>") fonts}
        <cachedir>${cache}</cachedir>
      </fontconfig>
    '';

  xdg.configFile."fontconfig/conf.d/30-default-fonts.conf".source = ./fonts.conf;
}
