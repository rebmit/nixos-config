{ profiles, suites, ... }:
{
  imports =
    with suites;
    [
      baseline
    ]
    ++ (with profiles; [
      # keep-sorted start
      applications.desktop
      darkman
      fcitx5
      firefox
      fontconfig
      gtk
      kitty
      qt
      xdg-user-dirs
      # keep-sorted end
    ]);
}
