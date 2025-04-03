{ ... }:
{
  services.logrotate = {
    enable = true;
    extraArgs = [
      "-s"
      "/var/lib/logrotate/status"
    ];
  };

  systemd.services.logrotate.serviceConfig = {
    StateDirectory = "logrotate";
  };

  preservation.preserveAt."/persist".directories = [ "/var/lib/logrotate" ];
}
