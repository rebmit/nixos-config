{ ... }:
{
  services.userborn = {
    enable = true;
    passwordFilesLocation = "/var/lib/nixos/userborn";
  };

  systemd.tmpfiles.settings.rebmit = {
    "/var/lib/nixos/userborn".d = {
      user = "root";
      group = "root";
      mode = "0755";
    };
  };
}
