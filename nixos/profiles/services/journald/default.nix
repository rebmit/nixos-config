{ ... }:
{
  services.journald.extraConfig = ''
    SystemMaxUse=1G
  '';

  preservation.preserveAt."/persist".directories = [ "/var/log/journal" ];
}
