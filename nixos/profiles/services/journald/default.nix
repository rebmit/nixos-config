{ ... }:
{
  services.journald.extraConfig = ''
    SystemMaxUse=1G
  '';

  preservation.preserveAt."/persist".directories = [
    {
      directory = "/var/log/journal";
      mode = "-";
      user = "-";
      group = "-";
    }
  ];
}
