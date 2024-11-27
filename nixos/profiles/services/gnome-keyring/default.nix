{ ... }:
{
  services.gnome.gnome-keyring.enable = true;

  environment.globalPersistence.user.directories = [ ".local/share/keyrings" ];
}
