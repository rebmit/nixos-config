{ lib, ... }:
{
  boot.tmp.useTmpfs = lib.mkDefault true;

  users.mutableUsers = lib.mkDefault false;

  time.timeZone = lib.mkDefault "Asia/Singapore";

  i18n.defaultLocale = lib.mkDefault "en_SG.UTF-8";

  environment.stub-ld.enable = lib.mkDefault false;

  documentation.nixos.enable = lib.mkForce false;

  environment.sessionVariables = {
    GOPROXY = "direct";
  };
}
