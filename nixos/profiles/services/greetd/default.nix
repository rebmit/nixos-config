{ pkgs, lib, ... }:
{
  services.greetd = {
    enable = true;
    settings = {
      default_session.command = "${lib.getExe pkgs.tuigreet} --cmd wayland-session";
    };
  };

  security.pam.services.swaylock = { };

  environment.pathsToLink = lib.singleton "/share/xdg-desktop-portal";
}
