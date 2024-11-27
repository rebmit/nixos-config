{ pkgs, lib, ... }:
{
  services.greetd = {
    enable = true;
    settings = {
      default_session.command = "${lib.getExe pkgs.greetd.tuigreet} --cmd wayland-session";
    };
  };

  security.pam.services.swaylock = { };
}
