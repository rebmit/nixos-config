{ pkgs, lib, ... }:
let
  inherit (lib.modules) mkDefault;
in
{
  nix.package = mkDefault pkgs.nixVersions.stable;
}
