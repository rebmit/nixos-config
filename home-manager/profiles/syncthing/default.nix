_:
{
  services.syncthing.enable = true;

  preservation.preserveAt."/persist".directories = [ ".local/state/syncthing" ];
}
