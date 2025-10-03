_: {
  services.pulseaudio.enable = false;

  services.pipewire = {
    enable = true;
    pulse.enable = true;
    jack.enable = true;
    alsa.enable = true;
    systemWide = true;
  };

  preservation.preserveAt."/persist".directories = [ "/var/lib/pipewire" ];
}
