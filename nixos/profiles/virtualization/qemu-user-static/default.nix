{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.lists) optionals remove;
  emulatedSystems = [
    "aarch64-linux"
    "riscv64-linux"
  ]
  ++ optionals (!config.virtualisation.rosetta.enable) [
    "x86_64-linux"
  ];
in
{
  boot.binfmt = {
    preferStaticEmulators = true;
    emulatedSystems = remove pkgs.stdenv.hostPlatform.system emulatedSystems;
  };
}
