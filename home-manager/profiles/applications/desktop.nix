{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # keep-sorted start
    dmlive
    evolution
    foliate
    gimp3
    libreoffice-fresh
    loupe
    mpv
    nautilus
    nheko
    papers
    seahorse
    swappy
    tdesktop
    zotero
    # keep-sorted end
  ];

  preservation.preserveAt."/persist".directories = [
    ".zotero"

    ".cache/evolution"
    ".cache/org.gnome.Evolution"
    ".config/dconf"
    ".config/evolution"
    ".config/nheko"
    ".local/share/evolution"
    ".local/share/org.gnome.Evolution"
    ".local/share/nheko"
    ".local/share/TelegramDesktop"

    ".pki/nssdb"

    "Zotero"
  ];
}
