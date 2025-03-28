{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.lists) filter;

  name = "rebmit";
  uid = config.ids.uids.${name};
  homeDirectory = "/home/${name}";

  groupNamesIfPresent =
    names:
    map (name: config.users.groups.${name}.name) (filter (name: config.users.groups ? ${name}) names);
in
{
  programs.fish.enable = true;

  users.users.${name} = {
    inherit uid;
    hashedPasswordFile = config.sops.secrets."user-password/${name}".path;
    isNormalUser = true;
    shell = pkgs.fish;
    home = homeDirectory;
    extraGroups = groupNamesIfPresent [
      "wheel"
      "pipewire"
    ];
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
