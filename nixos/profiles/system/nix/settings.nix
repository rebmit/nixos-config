{ ... }:
{
  nix = {
    channel.enable = false;
    settings = {
      trusted-users = [
        "root"
        "@wheel"
      ];
      experimental-features = [
        "nix-command"
        "flakes"
        "auto-allocate-uids"
        "cgroups"
        "ca-derivations"
      ];
      auto-allocate-uids = true;
      use-cgroups = true;
      auto-optimise-store = true;
      keep-outputs = true;
      keep-derivations = true;
      use-xdg-base-directories = true;
      builders-use-substitutes = true;
    };
  };

  systemd.services.nix-daemon.serviceConfig.Environment = [ "TMPDIR=/var/tmp" ];
}
