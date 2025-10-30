let
  common = _: {
    nix = {
      channel.enable = false;
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
          "ca-derivations"
        ];
        use-xdg-base-directories = true;
        keep-outputs = true;
        keep-derivations = true;
        builders-use-substitutes = true;
      };
    };
  };

  nixos = _: {
    nix = {
      settings = {
        experimental-features = [
          "auto-allocate-uids"
          "cgroups"
        ];
        auto-allocate-uids = true;
        use-cgroups = true;
        auto-optimise-store = true;
      };
    };

    systemd.services.nix-daemon.serviceConfig.Environment = [ "TMPDIR=/var/tmp" ];
  };

  darwin = _: {
    nix = {
      settings = {
        sandbox = true;
      };
      optimise.automatic = true;
    };
  };
in
{
  flake.modules.nixos."system/nix/settings".imports = [
    common
    nixos
  ];

  flake.modules.darwin."system/nix/settings".imports = [
    common
    darwin
  ];
}
