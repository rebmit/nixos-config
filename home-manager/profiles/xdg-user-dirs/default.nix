{ ... }:
{
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    desktop = "/var/empty";
    documents = "$HOME/Documents";
    download = "$HOME/Downloads";
    music = "$HOME/Music";
    pictures = "$HOME/Pictures";
    publicShare = "/var/empty";
    templates = "/var/empty";
    videos = "$HOME/Videos";
  };

  home.globalPersistence.directories = [
    "Documents"
    "Downloads"
    "Music"
    "Pictures"
    "Videos"
  ];
}
