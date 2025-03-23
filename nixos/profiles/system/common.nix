{ lib, ... }:
let
  inherit (lib.modules) mkDefault mkForce;
in
{
  boot.tmp.useTmpfs = mkDefault true;

  i18n.defaultLocale = mkDefault "en_SG.UTF-8";

  time.timeZone = mkDefault "Asia/Singapore";

  users.mutableUsers = mkDefault false;

  environment.stub-ld.enable = mkDefault false;

  documentation.nixos.enable = mkForce false;
}
