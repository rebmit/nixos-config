{ config, ... }:
{
  assertions = [
    {
      assertion = !config.boot.isContainer;
      message = ''
        `config.boot.initrd.systemd.enable` and `config.boot.isContainer`
        cannot be enabled at the same time.
      '';
    }
  ];

  boot.initrd.systemd.enable = true;
}
