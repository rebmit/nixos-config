{ lib, ... }:
let
  inherit (lib.modules) mkDefault mkForce;
in
{
  boot.tmp.useTmpfs = mkDefault true;

  i18n.defaultLocale = mkDefault "en_HK.UTF-8";

  time.timeZone = mkDefault "Asia/Hong_Kong";

  users.mutableUsers = mkDefault false;

  environment.stub-ld.enable = mkDefault false;

  documentation.nixos.enable = mkForce false;
}
