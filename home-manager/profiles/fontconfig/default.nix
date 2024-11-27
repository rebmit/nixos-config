{ pkgs, ... }:
{
  home.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-emoji
    roboto-mono
    (nerdfonts.override { fonts = [ "RobotoMono" ]; })
  ];

  fonts.fontconfig.enable = true;

  xdg.configFile."fontconfig/conf.d/30-default-fonts.conf".source = ./fonts.conf;
}
