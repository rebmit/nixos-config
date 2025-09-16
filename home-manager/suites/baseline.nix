{ profiles, ... }:
{
  imports = with profiles; [
    # keep-sorted start
    applications.base
    fish
    helix
    preservation
    theme.adwaita
    tmux
    yazi
    zoxide
    # keep-sorted end
  ];
}
