{ inputs, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.modules ];

  disabledModules = [
    "${inputs.flake-parts}/modules/apps.nix"
    "${inputs.flake-parts}/modules/nixosModules.nix"
    "${inputs.flake-parts}/modules/overlays.nix"
    "${inputs.flake-parts}/modules/packages.nix"
  ];
}
