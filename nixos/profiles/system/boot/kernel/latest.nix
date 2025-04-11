{ lib, pkgs, ... }:
let
  inherit (lib.modules) mkDefault;
in
{
  boot.kernelPackages = mkDefault pkgs.linuxPackages_latest;
}
