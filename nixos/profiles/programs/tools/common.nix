{ pkgs, ... }:
{
  programs = {
    command-not-found.enable = false;
    git = {
      enable = true;
      lfs.enable = true;
    };
    htop = {
      enable = true;
      settings = {
        show_program_path = 0;
        highlight_base_name = 1;
        hide_userland_threads = true;
      };
    };
  };

  environment.systemPackages = with pkgs; [
    # keep-sorted start
    coreutils
    file
    findutils
    gawk
    gnugrep
    gnused
    gnutar
    jq
    lsof
    p7zip
    psmisc
    tree
    unzipNLS
    which
    zip
    zstd
    # keep-sorted end
  ];
}
