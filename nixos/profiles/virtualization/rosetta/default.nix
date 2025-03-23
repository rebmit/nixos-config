{ lib, ... }:
let
  inherit (lib.modules) mkForce;
in
{
  virtualisation.rosetta.enable = true;

  # https://docs.getutm.app/advanced/rosetta/#enabling-rosetta
  boot.binfmt.registrations.rosetta.preserveArgvZero = mkForce true;
}
