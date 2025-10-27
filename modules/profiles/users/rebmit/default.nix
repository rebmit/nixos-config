{ config, ... }:
let
  inherit (config.flake) meta;
in
{
  flake.meta.users.rebmit = {
    name = "Lu Wang";
    email = "rebmit@rebmit.moe";
    authorizedKeys = [
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIDHK6V7pieTigHhvorso7yN3Gy2wu8jYY/qLD+3yh1PLAAAABHNzaDo="
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDfKG/KKgC6IaK4uu9zn+0wbF4XXK1pcCP/S37u6OAmJ"
    ];
  };

  flake.modules.nixos."users/rebmit" =
    { config, ... }:
    {
      programs.fish.enable = true;

      ids.uids.rebmit = 1000;

      users.users.rebmit = {
        uid = config.ids.uids.rebmit;
        shell = config.programs.fish.package;
        openssh.authorizedKeys.keys = meta.users.rebmit.authorizedKeys;
        isNormalUser = true;
        hashedPasswordFile = config.sops.secrets."user-password/rebmit".path;
        extraGroups = [
          "wheel"
          "pipewire"
        ];
      };

      sops.secrets."user-password/rebmit" = {
        neededForUsers = true;
        sopsFile = config.sops.secretFiles.get "common.yaml";
      };

      nix.settings.trusted-users = [ "rebmit" ];

      home-manager.users.rebmit = _: {
        programs.git.settings.user = {
          inherit (meta.users.rebmit) name email;
        };
      };
    };
}
