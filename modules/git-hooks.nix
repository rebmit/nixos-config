{ inputs, ... }:
{
  imports = [ inputs.git-hooks-nix.flakeModule ];

  perSystem =
    { config, pkgs, ... }:
    {
      pre-commit = {
        check.enable = false;
        settings.package = pkgs.prek;
      };

      devshells.default.devshell.startup.pre-commit-hook.text = config.pre-commit.installationScript;
    };
}
