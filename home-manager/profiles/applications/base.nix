{ config, pkgs, ... }:
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

  home.sessionVariables = {
    HISTFILE = "${config.xdg.stateHome}/bash_history";
    PYTHON_HISTORY = "${config.xdg.stateHome}/python_history";
  };

  programs.man.generateCaches = false;
}
