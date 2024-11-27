{ ... }:
{
  nix = {
    gc = {
      automatic = true;
      options = "--delete-older-than 14d";
      dates = "weekly";
    };

    settings.min-free = 1024 * 1024 * 1024; # bytes
  };
}
