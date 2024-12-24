{
  environment.globalPersistence = {
    enable = true;
    root = "/persist";
  };

  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
    fileSystems = [ "/persist" ];
  };
}
