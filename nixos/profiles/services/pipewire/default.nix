{ ... }:
{
  hardware.pulseaudio.enable = false;

  services.pipewire = {
    enable = true;
    pulse.enable = true;
    jack.enable = true;
    alsa.enable = true;
  };

  environment.globalPersistence.user.directories = [
    ".local/state/wireplumber"
  ];
}
