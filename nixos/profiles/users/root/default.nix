{ config, ... }:
{
  users.users.root = {
    hashedPasswordFile = config.sops.secrets."user-password/root".path;
    openssh.authorizedKeys.keyFiles = [
      ./_ssh/marisa-7d76
      ./_ssh/marisa-a7s
    ];
  };

  sops.secrets."user-password/root" = {
    neededForUsers = true;
    sopsFile = config.sops.secretFiles.get "common.yaml";
  };
}
