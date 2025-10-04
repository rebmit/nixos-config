{ lib, osConfig, ... }:
{
  preservation = {
    enable = true;
    directories = [
      ".cache/nix"
      ".local/share/nix"
      ".ssh"
    ]
    ++ lib.optionals osConfig.services.gnome.gnome-keyring.enable [
      ".local/share/keyrings"
    ];
  };
}
