# Portions of this file are sourced from
# https://github.com/linyinfeng/dotfiles/blob/d40b75ca0955d2a999b36fa1bd0f8b3a6e061ef3/home-manager/profiles/niri/default.nix (MIT License)
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cliphist = pkgs.cliphist;
in
lib.mkMerge [
  {
    home.packages = lib.singleton cliphist;

    systemd.user.services.cliphist = {
      Unit = {
        Description = "Clipboard management daemon";
        ConditionEnvironment = lib.singleton "WAYLAND_DISPLAY";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
        Requisite = [ "graphical-session.target" ];
      };
      Install.WantedBy = [ "graphical-session.target" ];
      Service = {
        Type = "simple";
        Restart = "on-failure";
        ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${cliphist}/bin/cliphist store";
      };
    };

    systemd.user.services.cliphist-images = {
      Unit = {
        Description = "Clipboard management daemon - images";
        ConditionEnvironment = lib.singleton "WAYLAND_DISPLAY";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
        Requisite = [ "graphical-session.target" ];
      };
      Install.WantedBy = [ "graphical-session.target" ];
      Service = {
        Type = "simple";
        Restart = "on-failure";
        ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${cliphist}/bin/cliphist store";
      };
    };
  }
  (lib.mkIf config.programs.fuzzel.enable {
    home.packages = with pkgs; [
      (pkgs.writeShellApplication {
        name = "cliphist-fuzzel";
        runtimeInputs = with pkgs; [
          wl-clipboard
          config.programs.fuzzel.package
          config.services.cliphist.package
        ];
        text = ''
          cliphist list | fuzzel -d | cliphist decode | wl-copy
        '';
      })
    ];
  })
]
