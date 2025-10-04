_: {
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  preservation.directories = [ ".local/share/direnv" ];
}
