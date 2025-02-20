{ ... }:
{
  programs.git = {
    enable = true;
    lfs.enable = true;
    signing = {
      format = "ssh";
      key = "~/.ssh/id_ed25519";
    };
    extraConfig = {
      commit.gpgSign = true;
      pull.rebase = true;
      init.defaultBranch = "master";
      fetch.prune = true;
    };
  };
}
