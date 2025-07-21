{ lib, osConfig, ... }:
{
  preservation = {
    enable = true;
    preserveAt."/persist" = {
      directories = [
        ".cache/nix"
        ".local/share/nix"
        ".ssh"
      ]
      ++ lib.optionals osConfig.services.gnome.gnome-keyring.enable [
        ".local/share/keyrings"
      ];
    };
  };
}
