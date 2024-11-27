{ ... }:
{
  nix = {
    channel.enable = false;
    settings = {
      trusted-users = [
        "root"
        "@wheel"
      ];
      experimental-features = [
        "nix-command"
        "flakes"
        "auto-allocate-uids"
        "cgroups"
      ];
      auto-allocate-uids = true;
      use-cgroups = true;
      auto-optimise-store = true;
      use-xdg-base-directories = true;
      builders-use-substitutes = true;
    };
  };

  environment.globalPersistence.user.directories = [
    ".cache/nix"
    ".local/share/nix"
  ];
}
