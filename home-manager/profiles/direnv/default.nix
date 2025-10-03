_: {
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  preservation.preserveAt."/persist".directories = [ ".local/share/direnv" ];
}
