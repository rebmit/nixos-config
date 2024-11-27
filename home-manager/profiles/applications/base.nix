{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # keep-sorted start
    fastfetch
    fd
    ffmpeg
    fzf
    numbat
    ripgrep
    # keep-sorted end
  ];
}
