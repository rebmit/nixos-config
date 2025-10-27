{ config, ... }:
let
  inherit (config.flake) meta;
in
{
  flake.modules.nixos."users/root" =
    { config, ... }:
    {
      users.users.root = {
        openssh.authorizedKeys.keys = meta.users.rebmit.authorizedKeys;
        hashedPasswordFile = config.sops.secrets."user-password/root".path;
      };

      sops.secrets."user-password/root" = {
        neededForUsers = true;
        sopsFile = config.sops.secretFiles.get "common.yaml";
      };
    };
}
