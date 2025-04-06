{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # keep-sorted start
    fastfetch
    fd
    ffmpeg
    fzf
    nixd
    numbat
    ripgrep
    # keep-sorted end
  ];

  services.ssh-agent.enable = true;
}
