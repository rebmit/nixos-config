{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # keep-sorted start
    celluloid
    dmlive
    evolution
    foliate
    libreoffice-fresh
    loupe
    nautilus
    nheko
    papers
    seahorse
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
