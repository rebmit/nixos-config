{
  lib,
  pkgs,
  ...
}:
{
  boot.binfmt.emulatedSystems = lib.remove pkgs.stdenv.hostPlatform.system [
    "aarch64-linux"
    "x86_64-linux"
  ];
}
