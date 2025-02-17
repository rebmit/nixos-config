{ lib, ... }:
{
  programs.git = {
    enable = true;
    lfs.enable = true;
    extraConfig = {
      commit.gpgSign = true;
      signing.format = "ssh";
      pull.rebase = true;
      init.defaultBranch = "master";
      fetch.prune = true;
    };
  };

  programs.git.signing.key = lib.mkDefault "~/.ssh/id_ed25519";
}
