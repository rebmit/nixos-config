{ config, mylib, ... }:
{
  services.vnstat.enable = true;

  environment.etc."vnstat.conf".text = ''
    UseUTC 1
  '';

  systemd.services.vnstat = {
    serviceConfig = mylib.misc.serviceHardened;
    restartTriggers = [ config.environment.etc."vnstat.conf".text ];
  };

  preservation.directories = [ "/var/lib/vnstat" ];
}
