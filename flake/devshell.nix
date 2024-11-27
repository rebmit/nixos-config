{
  perSystem =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      devshells.default = {
        packages = with pkgs; [
          just
          sops
          rage
          (opentofu.withPlugins (
            ps: with ps; [
              sops
              tls
            ]
          ))
        ];
        env = [
          (lib.nameValuePair "DEVSHELL_NO_MOTD" 1)
          # https://github.com/opentofu/opentofu/issues/1478
          (lib.nameValuePair "OPENTOFU_STATEFILE_PROVIDER_ADDRESS_TRANSLATION" 0)
        ];
        devshell.startup.pre-commit-hook.text = config.pre-commit.installationScript;
      };
    };
}
