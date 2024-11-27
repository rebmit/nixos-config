{
  lib,
  pkgs,
  mylib,
  ...
}:
{
  boot.binfmt.emulatedSystems = lib.remove pkgs.stdenv.hostPlatform.system mylib.systems;
}
