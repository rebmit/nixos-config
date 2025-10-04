_: {
  services.journald.extraConfig = ''
    SystemMaxUse=1G
  '';

  preservation.directories = [ "/var/log/journal" ];
}
