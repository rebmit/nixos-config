{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.lists) optional;

  name = "rebmit";
  uid = config.ids.uids.${name};
  homeDirectory = "/home/${name}";

  groupNameIfPresent =
    name: optional (config.users.groups ? ${name}) config.users.groups.${name}.name;
in
{
  programs.fish.enable = true;

  users.users.${name} = {
    inherit uid;
    hashedPasswordFile = config.sops.secrets."user-password/${name}".path;
    isNormalUser = true;
    shell = pkgs.fish;
    home = homeDirectory;
    extraGroups =
      with config.users.groups;
      [
        wheel.name
      ]
      ++ groupNameIfPresent "pipewire";
    openssh.authorizedKeys.keyFiles = config.users.users.root.openssh.authorizedKeys.keyFiles;
  };

  sops.secrets."user-password/${name}" = {
    neededForUsers = true;
    sopsFile = config.sops.secretFiles.get "local.yaml";
  };

  home-manager.users.${name} =
    { ... }:
    {
      programs.git = {
        userName = "Lu Wang";
        userEmail = "rebmit@rebmit.moe";
      };
    };
}
