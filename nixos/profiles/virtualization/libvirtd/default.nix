{ ... }:
{
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      runAsRoot = false;
      swtpm.enable = true;
    };
  };

  environment.globalPersistence.user.directories = [ ".config/libvirt" ];
}
