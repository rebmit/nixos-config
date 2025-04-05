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
    thunderbird
    zotero
    # keep-sorted end
  ];

  preservation.preserveAt."/persist".directories = [
    ".thunderbird"
    ".zotero"

    ".config/dconf"
    ".config/nheko"

    ".local/share/nheko"
    ".local/share/TelegramDesktop"

    "Zotero"
  ];
}
