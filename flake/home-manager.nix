# Portions of this file are sourced from
# https://github.com/linyinfeng/dotfiles/blob/b618b0fd16fb9c79ab7199ed51c4c0f98a392cea/flake/hosts.nix
{
  inputs,
  lib,
  ...
}:
let
  inherit (inputs.rebmit.lib.path) buildModuleList rakeLeaves;
  buildSuites = profiles: f: lib.mapAttrs (_: lib.flatten) (lib.fix (f profiles));

  homeModules = buildModuleList ../home-manager/modules;
  homeProfiles = rakeLeaves ../home-manager/profiles;
  homeSuites = buildSuites homeProfiles (
    profiles: suites: {
      baseline = with profiles; [
        # keep-sorted start
        applications.base
        fish
        helix
        preservation
        tmux
        yazi
        # keep-sorted end
      ];

      development = with profiles; [
        # keep-sorted start
        development
        direnv
        git
        # keep-sorted end
      ];

      workstation = suites.baseline ++ suites.development;

      desktop-baseline =
        suites.baseline
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
          theme.catppuccin
          valent
          xdg-user-dirs
          # keep-sorted end
        ]);

      desktop-niri = with profiles; [
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

      desktop-workstation = suites.workstation ++ suites.desktop-baseline ++ suites.desktop-niri;
    }
  );
in
{
  passthru = {
    inherit homeModules homeProfiles homeSuites;
  };
}
