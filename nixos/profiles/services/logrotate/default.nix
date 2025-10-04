_: {
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

  preservation.directories = [ "/var/lib/logrotate" ];
}
