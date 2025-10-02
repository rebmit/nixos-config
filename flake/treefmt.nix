{
  perSystem =
    { config, lib, ... }:
    let
      inherit (lib.modules) mkForce;
      inherit (lib.lists) singleton;
      inherit (lib.meta) getExe;
    in
    {
      treefmt = {
        projectRootFile = "flake.nix";
        programs = {
          nixfmt.enable = true;
          deadnix.enable = true;
          terraform.enable = true;
          prettier.enable = true;
          keep-sorted.enable = true;
          statix.enable = true;
        };
        settings.formatter = {
          keep-sorted = {
            includes = mkForce [ "*.nix" ];
          };
        };
      };

      devshells.default.packages = singleton config.treefmt.build.wrapper;

      pre-commit.settings.hooks = {
        treefmt = {
          enable = true;
          name = "treefmt";
          entry = getExe config.treefmt.build.wrapper;
          pass_filenames = false;
        };
      };
    };
}
