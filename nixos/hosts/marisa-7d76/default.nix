{
  suites,
  profiles,
  mylib,
  flake,
  ...
}:
{
  imports = [
    suites.workstation
    profiles.virtualization.qemu-user-static
    flake.flake.modules.nixos."users/rebmit"
  ]
  ++ (mylib.path.scanPaths ./. "default.nix");

  home-manager.users.rebmit =
    { suites, profiles, ... }:
    {
      imports = [
        suites.desktop-workstation
        profiles.syncthing
      ];

      programs.niri.settings = {
        outputs = {
          "HDMI-A-1" = {
            scale = 1.75;
          };
          "DP-1" = {
            scale = 1.75;
            position = {
              x = 0;
              y = 0;
            };
          };
        };
      };
    };

  documentation = {
    enable = true;
    doc.enable = false;
    info.enable = false;
    man = {
      enable = true;
      generateCaches = false;
    };
    nixos.enable = false;
  };

  environment.defaultPackages = [ ];

  system.stateVersion = "24.11";
}
