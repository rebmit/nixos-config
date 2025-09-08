{
  config,
  lib,
  pkgs,
  ...
}:
{
  gtk = {
    enable = true;
    gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
    cursorTheme = {
      name = config.theme.cursorTheme;
      size = config.theme.cursorSize;
    };
  };

  # https://github.com/nix-community/home-manager/pull/5206
  # https://github.com/nix-community/home-manager/commit/e9b9ecef4295a835ab073814f100498716b05a96
  xdg.configFile."gtk-4.0/gtk.css" = lib.mkForce {
    text = config.gtk.gtk4.extraCss;
  };

  home.sessionVariables = {
    GTK_USE_PORTAL = "1";
  };

  services.darkman =
    let
      mkScript =
        mode:
        let
          inherit (config.theme.${mode})
            gtkTheme
            iconTheme
            ;
        in
        pkgs.writeShellApplication {
          name = "darkman-switch-gtk-${mode}";
          runtimeInputs = with pkgs; [
            dconf
          ];
          text = ''
            dconf write /org/gnome/desktop/interface/color-scheme "'prefer-${mode}'"
            dconf write /org/gnome/desktop/interface/gtk-theme "'${gtkTheme}'"
            dconf write /org/gnome/desktop/interface/icon-theme "'${iconTheme}'"
          '';
        };
    in
    {
      lightModeScripts.gtk = "${lib.getExe (mkScript "light")}";
      darkModeScripts.gtk = "${lib.getExe (mkScript "dark")}";
    };
}
