{ profiles, ... }:
{
  imports = with profiles; [
    # keep-sorted start
    programs.dconf
    programs.tools.system
    security.rtkit
    services.gnome-keyring
    services.greetd
    services.pipewire
    # keep-sorted end
  ];
}
