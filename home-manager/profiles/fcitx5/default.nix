{ pkgs, lib, ... }:
let
  fcitx5Package = pkgs.qt6Packages.fcitx5-with-addons.override {
    addons = with pkgs; [
      qt6Packages.fcitx5-chinese-addons
      fcitx5-pinyin-zhwiki
    ];
    withConfigtool = false;
  };
in
{
  home.packages = lib.singleton fcitx5Package;

  systemd.user.services.fcitx5-daemon = {
    Unit = {
      Description = "Fcitx5 input method editor";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      Requisite = [ "graphical-session.target" ];
    };
    Service.ExecStart = "${fcitx5Package}/bin/fcitx5";
    Install.WantedBy = [ "graphical-session.target" ];
  };

  xdg.configFile."fcitx5" = {
    source = ./_config;
    force = true;
    recursive = true;
  };

  systemd.user.sessionVariables = {
    QT_IM_MODULE = "fcitx";
  };
}
