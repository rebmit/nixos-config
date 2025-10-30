let
  common = _: {
    nix = {
      gc = {
        automatic = true;
        options = "--delete-older-than 14d";
      };

      settings.min-free = 1024 * 1024 * 1024; # bytes
    };
  };

  nixos = _: {
    nix.gc.dates = "weekly";
  };

  darwin = _: {
    nix.gc.interval = [
      {
        Weekday = 7;
        Hour = 3;
        Minute = 15;
      }
    ];
  };
in
{
  flake.modules.nixos."system/nix/gc".imports = [
    common
    nixos
  ];

  flake.modules.darwin."system/nix/gc".imports = [
    common
    darwin
  ];
}
