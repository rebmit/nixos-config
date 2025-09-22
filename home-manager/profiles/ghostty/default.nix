{
  lib,
  ...
}:
{
  programs.ghostty = {
    enable = true;
    settings = {
      font-family = "monospace";
      font-size = 12;
      theme = "light:Adwaita,dark:Adwaita Dark";
      gtk-single-instance = true;
    };
  };

  programs.fuzzel.settings.main.terminal = lib.mkDefault "ghostty";
}
