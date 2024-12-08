{
  config,
  pkgs,
  lib,
  ...
}:
let
  swww = pkgs.swww;
in
{
  systemd.user.services.swww-daemon = {
    Unit = {
      Description = "A Solution to your Wayland Wallpaper Woes";
      Documentation = "https://github.com/LGFae/swww";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      Requisite = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${swww}/bin/swww-daemon --no-cache";
      ExecStartPost = "${swww}/bin/swww img %h/.config/swww/wallpaper";
      Restart = "on-failure";
      KillMode = "mixed";
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.tmpfiles.rules = [
    "L %h/.config/swww/wallpaper - - - - ${config.theme.light.wallpaper}"
  ];

  services.darkman =
    let
      mkScript =
        mode:
        pkgs.writeShellApplication {
          name = "darkman-switch-swww-${mode}";
          text = ''
            ln --force --symbolic --verbose "${config.theme.${mode}.wallpaper}" "$HOME/.config/swww/wallpaper"
            if ! ${config.systemd.user.systemctlPath} --user is-active swww-daemon; then
              echo "swww-daemon is not active"
              exit 1
            fi
            ${swww}/bin/swww img ~/.config/swww/wallpaper
          '';
        };
    in
    {
      lightModeScripts.swww = "${lib.getExe (mkScript "light")}";
      darkModeScripts.swww = "${lib.getExe (mkScript "dark")}";
    };
}
