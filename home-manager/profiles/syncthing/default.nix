{ ... }:
{
  services.syncthing.enable = true;

  home.globalPersistence.directories = [ ".local/state/syncthing" ];
}
