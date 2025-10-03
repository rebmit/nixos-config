{
  inputs,
  lib,
  ...
}:
let
  inherit (lib.meta) getExe;
in
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem =
    { config, ... }:
    {
      treefmt = {
        flakeCheck = false;
        projectRootFile = "flake.nix";
        programs = {
          deadnix.enable = true;
          keep-sorted.enable = true;
          nixfmt.enable = true;
          prettier.enable = true;
          statix.enable = true;
          terraform.enable = true;
        };
      };

      pre-commit.settings.hooks.treefmt = {
        enable = true;
        name = "treefmt";
        entry = getExe config.treefmt.build.wrapper;
        pass_filenames = false;
      };
    };
}
