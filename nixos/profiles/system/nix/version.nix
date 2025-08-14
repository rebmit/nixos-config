{ lib, pkgs, ... }:
let
  inherit (lib.modules) mkDefault;
in
{
  nix.package = mkDefault pkgs.nixVersions.latest;
}
