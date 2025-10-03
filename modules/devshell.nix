{
  inputs,
  lib,
  ...
}:
let
  inherit (lib.attrsets) nameValuePair;
in
{
  imports = [ inputs.devshell.flakeModule ];

  perSystem =
    { pkgs, ... }:
    {
      devshells.default = {
        packages = with pkgs; [
          just
          sops
          rage
          age-plugin-yubikey
          nixos-anywhere
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
      };
    };
}
