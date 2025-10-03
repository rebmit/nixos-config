_: {
  nix = {
    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
      dates = "weekly";
    };

    settings.min-free = 1024 * 1024 * 1024; # bytes
  };
}
