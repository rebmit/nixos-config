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
      ghostty
      gtk
      qt
      xdg-user-dirs
      # keep-sorted end
    ]);
}
