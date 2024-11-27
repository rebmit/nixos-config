{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # keep-sorted start
    celluloid
    foliate
    libreoffice-fresh
    loupe
    nheko
    papers
    seahorse
    tdesktop
    thunderbird
    zotero-beta
    # keep-sorted end
  ];

  home.globalPersistence.directories = [
    ".thunderbird"
    ".zotero"

    ".config/nheko"

    ".local/share/nheko"
    ".local/share/TelegramDesktop"

    "Zotero"
  ];
}
