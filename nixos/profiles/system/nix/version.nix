{ lib, pkgs, ... }:
let
  inherit (lib.modules) mkDefault;
in
{
  # TODO: wait for the related issues to be resolved
  # https://github.com/NixOS/nix/issues/13000
  nix.package = mkDefault pkgs.nixVersions.nix_2_24;
}
