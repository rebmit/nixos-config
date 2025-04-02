# Portions of this file are sourced from
# https://github.com/linyinfeng/dotfiles/blob/b618b0fd16fb9c79ab7199ed51c4c0f98a392cea/flake/hosts.nix (MIT License)
{
  inputs,
  lib,
  ...
}:
let
  inherit (inputs.rebmit.lib.path) buildModuleList rakeLeaves;

  homeModules = buildModuleList ../home-manager/modules;
  homeProfiles = rakeLeaves ../home-manager/profiles;
  homeSuites = rakeLeaves ../home-manager/suites;
in
{
  passthru = {
    inherit homeModules homeProfiles homeSuites;
  };
}
