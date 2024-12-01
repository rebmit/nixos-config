{ config, pkgs, ... }:
let
  uid = config.ids.uids.rebmit;
  homeDirectory = "/home/rebmit";
in
{
  programs.fish.enable = true;

  users.users.rebmit = {
    inherit uid;
    hashedPasswordFile = config.sops.secrets."user-password/rebmit".path;
    isNormalUser = true;
    shell = pkgs.fish;
    home = homeDirectory;
    extraGroups = with config.users.groups; [
      wheel.name
    ];
    openssh.authorizedKeys.keyFiles = config.users.users.root.openssh.authorizedKeys.keyFiles;
  };

  sops.secrets."user-password/rebmit" = {
    neededForUsers = true;
    sopsFile = config.sops.secretFiles.get "local.yaml";
  };

  environment.globalPersistence.user.users = [ "rebmit" ];

  home-manager.users.rebmit =
    { ... }:
    {
      home.globalPersistence = {
        enable = true;
        home = homeDirectory;
      };

      programs.git = {
        userName = "Lu Wang";
        userEmail = "rebmit@rebmit.moe";
      };
    };
}
