{
  perSystem =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.attrsets) nameValuePair;
    in
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
              random
              vultr
              terraform-providers-bin.providers.Backblaze.b2
            ]
          ))
        ];
        env = [
          (nameValuePair "DEVSHELL_NO_MOTD" 1)
        ];
        devshell.startup.pre-commit-hook.text = config.pre-commit.installationScript;
      };
    };
}
