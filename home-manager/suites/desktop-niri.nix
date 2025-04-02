{ profiles, ... }:
{
  imports = with profiles; [
    # keep-sorted start
    cliphist
    fuzzel
    mako
    niri
    polkit-gnome
    swaylock
    swww
    waybar.niri
    # keep-sorted end
  ];
}
