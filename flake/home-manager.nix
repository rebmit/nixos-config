# Portions of this file are sourced from
# https://github.com/linyinfeng/dotfiles/blob/b618b0fd16fb9c79ab7199ed51c4c0f98a392cea/flake/hosts.nix (MIT License)
{
  inputs,
  self,
  data,
  mylib,
  ...
}:
let
  inherit (mylib.path) buildModuleList rakeLeaves;

  homeModules = buildModuleList ../home-manager/modules;
  homeProfiles = rakeLeaves ../home-manager/profiles;
  homeSuites = rakeLeaves ../home-manager/suites;

  homeSpecialArgs = name: {
    inherit
      inputs
      self
      data
      mylib
      ;
    profiles = homeProfiles;
    suites = homeSuites;
    host = data.hosts."${name}";
  };

  homeCommonModules =
    _name:
    homeModules
    ++ [
      inputs.niri-flake.homeModules.niri
    ];
in
{
  passthru = {
    inherit
      homeModules
      homeProfiles
      homeSuites
      homeSpecialArgs
      homeCommonModules
      ;
  };
}
