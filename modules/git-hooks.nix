{ inputs, ... }:
{
  imports = [ inputs.git-hooks-nix.flakeModule ];

  perSystem =
    { config, ... }:
    {
      pre-commit.check.enable = false;

      devshells.default.devshell.startup.pre-commit-hook.text = config.pre-commit.installationScript;
    };
}
