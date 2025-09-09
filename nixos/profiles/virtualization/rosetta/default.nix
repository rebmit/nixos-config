{ lib, pkgs, ... }:
let
  inherit (lib.modules) mkForce;
in
{
  virtualisation.rosetta.enable = true;

  # https://docs.getutm.app/advanced/rosetta/#enabling-rosetta
  boot.binfmt.registrations.rosetta.preserveArgvZero = mkForce true;

  # TODO: remove workaround for rosetta error: unhandled auxillary vector type 29
  # https://github.com/utmapp/UTM/discussions/6799
  boot.kernelPackages = pkgs.linuxPackages_6_12;
}
