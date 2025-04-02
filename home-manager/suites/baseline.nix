{ profiles, ... }:
{
  imports = with profiles; [
    # keep-sorted start
    applications.base
    fish
    helix
    preservation
    theme.catppuccin
    tmux
    yazi
    # keep-sorted end
  ];
}
