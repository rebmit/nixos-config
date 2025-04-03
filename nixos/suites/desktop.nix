{ profiles, ... }:
{
  imports = with profiles; [
    # keep-sorted start
    programs.dconf
    programs.system
    security.rtkit
    services.gnome-keyring
    services.greetd
    services.pipewire
    # keep-sorted end
  ];
}
