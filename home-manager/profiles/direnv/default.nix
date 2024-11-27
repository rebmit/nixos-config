{ ... }:
{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home.globalPersistence.directories = [ ".local/share/direnv" ];
}
